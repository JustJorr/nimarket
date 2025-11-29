import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
      ),
      body: Container(
        height: double.infinity,
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
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Error loading orders", style: TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
                child: Text("No orders yet", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;

              return Card(
                color: Colors.blueGrey[900],
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    data["customerName"] ?? "No name",
                    style: const TextStyle(color: Colors.amber),
                  ),
                  subtitle: Text(
                    "Total: Rp${(data["total"] ?? 0).toStringAsFixed(2)}\nStatus: ${data["status"]}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id, data: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.data,
  });

  Future<void> updateStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection("orders").doc(orderId).update({
      "status": newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = (data["items"] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
      ),
      body: Container(
        height: double.infinity,
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
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              // Order ID and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Order ID: $orderId',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (data["status"] ?? 'pending') == 'completed'
                        ? Colors.green
                        : (data["status"] ?? 'pending') == 'processing'
                            ? Colors.orange
                            : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data["status"] ?? "pending",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Details
            const Text('Customer Details', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Name: ${data["customerName"] ?? "Unknown"}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('Address: ${data["address"] ?? "No address"}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('Phone: ${data["phone"] ?? "No phone"}', style: const TextStyle(color: Colors.white, fontSize: 16)),

            const SizedBox(height: 16),

            // Items Section
            const Text('Items', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((item) {
              final name = item["name"] ?? "Unknown Item";
              final qty = item["qty"] ?? 1;
              final price = (item["price"] is num) ? (item["price"] as num).toDouble() : 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(name, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Quantity: $qty', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    Text('Rp${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Total Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Total', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'Rp${((data["total"] is num) ? (data["total"] as num).toDouble() : 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Date Section
            if (data['createdAt'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Date', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${(data['createdAt'] as Timestamp).toDate()}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Update Status
            const Text("Update Status", style: TextStyle(fontSize: 18, color: Colors.amber)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => updateStatus("pending"),
                  child: const Text("Pending"),
                ),
                ElevatedButton(
                  onPressed: () => updateStatus("processing"),
                  child: const Text("Processing"),
                ),
                ElevatedButton(
                  onPressed: () => updateStatus("completed"),
                  child: const Text("Completed"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Delete Order Button
            ElevatedButton.icon(
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Order"),
                    content: const Text("Are you sure you want to delete this order? This action cannot be undone."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (shouldDelete == true) {
                  await FirebaseFirestore.instance.collection("orders").doc(orderId).delete();
                  Navigator.of(context).pop(); // Go back to manage orders
                }
              },
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Delete Order"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

