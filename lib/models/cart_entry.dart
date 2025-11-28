
import 'item.dart';

class CartEntry {
  final Item item;
  int qty;

  CartEntry({required this.item, this.qty = 1});

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'qty': qty,
    };
  }

  factory CartEntry.fromMap(Map<String, dynamic>? map) {
  if (map == null ||
      map['item'] == null ||
      map['item'] is! Map<String, dynamic>) {
    return CartEntry(
      item: Item(
        id: '',
        name: 'Unknown Item',
        imageUrl: '',
        price: 0.0,
        stock: 0,
        category: 'goods',
        shopId: '',
      ),
      qty: 1,
    );
  }

  return CartEntry(
    item: Item.fromMap(map['item'] as Map<String, dynamic>),
    qty: (map['qty'] as num?)?.toInt() ?? 1,
    );
  }
}
