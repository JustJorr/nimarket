import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_entry.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartEntry> items;
  final double total;
  final String address;
  final String customerName;
  final String phone;
  final String status;
  final Timestamp createdAt;
  final String shopId;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.address,
    required this.customerName,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.shopId,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'address': address,
        'customerName': customerName,
        'phone': phone,
        'status': status,
        'createdAt': createdAt,
        'shopId': shopId,
      };

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return OrderModel(
        id: doc.id,
        userId: '',
        items: [],
        total: 0,
        address: '',
        customerName: '',
        phone: '',
        status: 'pending',
        createdAt: Timestamp.now(),
        shopId: "",
      );
    }

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] ?? '',
      customerName: data['customerName'] ?? '',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt']
          : Timestamp.now(),
      shopId: data['shopId'] ?? "",
    );
  }
}
