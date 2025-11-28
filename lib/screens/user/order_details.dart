import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/item.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  final void Function(Item) onReorderItem;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.onReorderItem,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'delivering':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 7, 12, 156),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 7, 12, 156),
              Color.fromARGB(255, 4, 3, 49),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _statusIcon(order.status),
                    color: _statusColor(order.status),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(order.status),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  itemCount: order.items.length,
                  itemBuilder: (ctx, i) {
                    final entry = order.items[i];
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: entry.item.imageUrl.isNotEmpty
                            ? Image.network(entry.item.imageUrl,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.shop, size: 50, color: Colors.white),
                        title: Text(
                          entry.item.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${entry.qty} × \$${entry.item.price}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          "\$${(entry.qty * entry.item.price).toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Total: \$${order.total.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reorder Items"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    for (var e in order.items) {
                      onReorderItem(e.item);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Items added back to cart!")),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
