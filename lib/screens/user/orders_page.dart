import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order.dart';
import '../../models/item.dart';
import 'order_details.dart';

class OrdersPage extends StatelessWidget {
  final void Function(Item) onReorderItem;

  const OrdersPage({super.key, required this.onReorderItem});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivering':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text("Login required", style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No orders yet", style: TextStyle(color: Colors.white)),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final order = OrderModel.fromFirestore(docs[index]);

            return Card(
              color: const Color.fromARGB(255, 16, 22, 95),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(
                  "Order #${order.id.substring(0, 6)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  "${order.createdAt.toDate().toString().substring(0, 16)}\nTotal: \$${order.total.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  order.status,
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsPage(
                        order: order,
                        onReorderItem: onReorderItem,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
