import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Shop shop;
  final void Function(Item) onAddToCart;

  const ShopDetailsScreen({
    required this.shop,
    required this.onAddToCart,
    super.key,
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  List<Item> _items = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .collection('items')
          .get();

      final items = snapshot.docs.map((d) {
        final data = d.data();
        return Item(
          id: d.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          stock: data['stock'] is num
              ? (data['stock'] as num).toInt()
              : int.tryParse(data['stock']?.toString() ?? '0') ?? 0,
          category: data['category']?.toString() ?? 'goods',
          shopId: widget.shop.id,
        );
      }).toList();

      setState(() {
        _items = items;
        _loadingItems = false;
      });
    } catch (e) {
      setState(() => _loadingItems = false);
    }
  }

  Future<void> _submitRating(double selectedRating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shopRef =
        FirebaseFirestore.instance.collection('shops').doc(widget.shop.id);

    final shopDoc = await shopRef.get();
    final data = shopDoc.data() ?? {};

    final ratings = (data['ratings'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    ratings.removeWhere((r) => r['userId'] == user.uid);

    ratings.add({
      'userId': user.uid,
      'rating': selectedRating,
      'timestamp': Timestamp.now(),
    });

    final avg = ratings
            .map((e) => (e['rating'] as num).toDouble())
            .reduce((a, b) => a + b) /
        ratings.length;

    await shopRef.update({
      'ratings': ratings,
      'rating': avg,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thanks for your rating!")),
    );
  }

  void _showRatingDialog(double currentRating) {
    double selectedRating = currentRating;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Rate ${widget.shop.name}"),
        content: RatingBar.builder(
          initialRating: currentRating,
          minRating: 1,
          allowHalfRating: true,
          itemBuilder: (_, __) =>
              const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (v) => selectedRating = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitRating(selectedRating);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .snapshots(),
      builder: (context, shopSnap) {
        if (!shopSnap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = shopSnap.data!.data() as Map<String, dynamic>;
        final shopRating = (data['rating'] ?? 0).toDouble();
        final shopName = data['name'] ?? widget.shop.name;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.amber,
            child: const Icon(Icons.star, color: Colors.white),
            onPressed: () => _showRatingDialog(shopRating),
          ),
          appBar: AppBar(
            title: Text(shopName, style: const TextStyle(color: Colors.white)),
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
            child: _loadingItems
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          data['description'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Expanded(
                        child: _items.isEmpty
                            ? const Center(
                                child: Text("No items available",
                                    style: TextStyle(color: Colors.white)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final item = _items[i];
                                  return Card(
                                    color: const Color.fromARGB(255, 4, 3, 49),
                                    child: ListTile(
                                      leading: item.imageUrl.isNotEmpty
                                          ? Image.network(item.imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover)
                                          : const Icon(Icons.image, color: Colors.white),
                                      title: Text(item.name,
                                          style: const TextStyle(color: Colors.white)),
                                      subtitle: Text(
                                          "\$${item.price.toStringAsFixed(2)}",
                                          style:
                                              const TextStyle(color: Colors.white)),
                                      trailing: IconButton(
                                        icon:
                                            const Icon(Icons.add_shopping_cart),
                                        color: item.stock > 0 ? Colors.white : Colors.grey,
                                        onPressed: item.stock > 0
                                            ? () => widget.onAddToCart(item)
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
