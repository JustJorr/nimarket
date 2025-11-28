import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

class Shop {
  final String id;
  final String name;
  final String description;
  final String bannerUrl;
  bool active;
  final List<Item> items;
  double rating;
  final List<Map<String, dynamic>> ratings;
  String? ownerId;      
  String? ownerUsername;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerUrl,
    this.active = true,
    List<Item>? items,
    this.rating = 0.0,
    List<Map<String, dynamic>>? ratings,
    this.ownerId,
    this.ownerUsername,
  })  : items = items ?? [],
        ratings = ratings ?? [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'bannerUrl': bannerUrl,
        'active': active,
        'items': items,
        'rating': rating,
        'ratings': ratings,
        'ownerId': ownerId,
        'ownerUsername': ownerUsername,
      };

  factory Shop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Shop(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      active: data['active'] ?? true,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => Item.fromMap(e))
          .toList(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratings: (data['ratings'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      ownerId: data['ownerId'],
      ownerUsername: data['ownerUsername'],
    );
  }
}
