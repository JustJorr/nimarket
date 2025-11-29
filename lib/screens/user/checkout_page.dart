import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_entry.dart';


class CheckoutPage extends StatefulWidget {
  final List<CartEntry> cart;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;

Future<void> placeOrder() async {
  if (_nameCtrl.text.isEmpty ||
      _addressCtrl.text.isEmpty ||
      _phoneCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Fill all fields")));
    return;
  }

  setState(() => _loading = true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to place an order")),
      );
      return;
    }

    final shopId = widget.cart.isNotEmpty
        ? widget.cart.first.item.shopId
        : "";

    await FirebaseFirestore.instance.collection("orders").add({
      "userId": user.uid,
      "customerName": _nameCtrl.text,
      "address": _addressCtrl.text,
      "phone": _phoneCtrl.text,
      "items": widget.cart.map((c) => c.toMap()).toList(),
      "total": widget.total,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "shopId": shopId,
    });

    setState(() => _loading = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Order Placed!"),
        content: const Text("Your order has been recorded."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  } catch (e) {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
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
        child: ListView(
          children: [
            const Text("Order Summary",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),

            // Cart list
            ...widget.cart.map((c) => ListTile(
                  title: Text(c.item.name,
                      style: const TextStyle(color: Colors.amber)),
                  subtitle: Text(
                    "Qty: ${c.qty} × \$${c.item.price}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                )),

            const Divider(color: Colors.white),
            Text("Total: Rp${widget.total.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            const Text("Customer Info",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),

            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Address",
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Phone",
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),

            const SizedBox(height: 30),

            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber))
                : ElevatedButton(
                    onPressed: placeOrder,
                    child: const Text("Place Order"),
                  ),
          ],
        ),
      ),
    );
  }
}
