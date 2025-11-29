import 'package:flutter/material.dart';
import 'checkout_page.dart';
import '../../models/cart_entry.dart';

class CartPage extends StatefulWidget {
  final List<CartEntry> cart;
  final void Function(String, int) onChangeQty;
  final double total;

  const CartPage({
    required this.cart,
    required this.onChangeQty,
    required this.total,
    super.key,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 7, 12, 156),
            Color.fromARGB(255, 4, 3, 49),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: widget.cart.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (ctx, i) {
                      final entry = widget.cart[i];
                      return ListTile(
                        title: Text(entry.item.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "\$${entry.item.price} x ${entry.qty}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 32,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  widget.onChangeQty(
                                      entry.item.id, entry.qty - 1);
                                });
                              },
                            ),
                            Text(entry.qty.toString(),
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 32,
                              color: Colors.white,
                              onPressed: () {
                                setState(() {
                                  widget.onChangeQty(
                                      entry.item.id, entry.qty + 1);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total: Rp${widget.total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              cart: widget.cart,
                              total: widget.total,
                            ),
                          ),
                        );
                      },
                      child: const Text("Checkout"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
