class Item {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  int stock;
  final String category;
  final String shopId;

  Item({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.category,
    required this.shopId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'stock': stock,
        'category': category,
        'shopId': shopId,
      };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      stock: (map['stock'] is num) ? (map['stock'] as num).toInt() : int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      category: map['category']?.toString() ?? 'goods',
      shopId: map['shopId']?.toString() ?? '',
    );
  }

  Item copyWith({
    String? name,
    String? imageUrl,
    double? price,
    int? stock,
    String? category,
    String? shopId,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      shopId: shopId ?? this.shopId,
    );
  }
}
