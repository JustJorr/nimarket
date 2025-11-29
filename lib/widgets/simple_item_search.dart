import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/item.dart';

class SimpleItemSearch extends SearchDelegate<Item?> {
  final List<Shop> shops;
  final void Function(Item) onAddToCart;
  final void Function(Shop) onOpenShop;
  final String filter;

  SimpleItemSearch(this.shops, this.onAddToCart, this.onOpenShop, {this.filter = 'all'});

  List<Item> get allItems => shops.where((s) => s.active).expand((s) => s.items).toList();

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white)
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  List<Item> _applyFilter(List<Item> items) {
    if (filter == 'all') return items;
    return items.where((i) => i.category == filter).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final lower = query.toLowerCase();
    var queryItems = allItems.where((i) => i.name.toLowerCase().contains(lower)).toList();
    queryItems = _applyFilter(queryItems);
    var queryShops = shops.where((s) => s.active && s.name.toLowerCase().contains(lower)).toList();
    List<dynamic> results = [...queryShops, ...queryItems];

    return Container(
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
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (ctx, i) {
          final result = results[i];
          if (result is Shop) {
            return ListTile(
              leading: result.bannerUrl.isNotEmpty
                  ? Image.network(result.bannerUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.store, color: Colors.white),
              title: Text(result.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(result.description, style: const TextStyle(color: Colors.white)),
              onTap: () => onOpenShop(result),
            );
          } else {
            final item = result as Item;
            return ListTile(
              leading: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image, color: Colors.white),
              title: Text(item.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text("Rp${item.price.toStringAsFixed(2)} - ${item.category}", style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                onPressed: () {
                  onAddToCart(item);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("${item.name} added to cart")));
                },
              ),
              onTap: () {},
            );
          }
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }
}
