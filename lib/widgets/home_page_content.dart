import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/item.dart';

class HomePageContent extends StatefulWidget {
  final List<Shop> shops;
  final void Function(Shop) onShopTap;
  final void Function(Item) onItemTap;
  final String selectedFilter;
  final void Function(String) onFilterChanged;

  const HomePageContent({
    required this.shops,
    required this.onShopTap,
    required this.onItemTap,
    required this.selectedFilter,
    required this.onFilterChanged,
    super.key,
  });

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  Widget buildFilterButton(VoidCallback onTap, String currentLabel) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.32),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, color: Color.fromARGB(255, 37, 0, 157), size: 18),
            const SizedBox(width: 8),
            Text(
              currentLabel,
              style: const TextStyle(
                color: Color.fromARGB(255, 37, 0, 157),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: Color.fromARGB(255, 37, 0, 157), size: 18),
          ],
        ),
      ),
    );
  }

  void showFilterSheet() {
    final current = widget.selectedFilter;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 4, 3, 49),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filter items',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All', style: TextStyle(color: Colors.black)),
                    selected: current == 'all',
                    onSelected: (_) {
                      widget.onFilterChanged('all');
                      Navigator.pop(ctx);
                    },
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  ChoiceChip(
                    label: const Text('Goods', style: TextStyle(color: Colors.black)),
                    selected: current == 'goods',
                    onSelected: (_) {
                      widget.onFilterChanged('goods');
                      Navigator.pop(ctx);
                    },
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  ChoiceChip(
                    label: const Text('Services', style: TextStyle(color: Colors.black)),
                    selected: current == 'services',
                    onSelected: (_) {
                      widget.onFilterChanged('services');
                      Navigator.pop(ctx);
                    },
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  widget.onFilterChanged('all');
                  Navigator.pop(ctx);
                },
                child: const Text('Reset to All', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String labelFromFilter(String f) {
    switch (f) {
      case 'goods':
        return 'Goods';
      case 'services':
        return 'Services';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShops = widget.shops.where((s) => s.active).toList();
    final allItems = activeShops.expand((s) => s.items).cast<Item>().toList();

    final filteredItems = widget.selectedFilter == 'all'
        ? allItems
        : allItems.where((i) => i.category == widget.selectedFilter).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Shops",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeShops.length,
              itemBuilder: (ctx, i) {
                final shop = activeShops[i];
                return GestureDetector(
                  onTap: () => widget.onShopTap(shop),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      color: const Color.fromARGB(255, 4, 3, 49),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: shop.bannerUrl.isNotEmpty
                                ? Image.network(shop.bannerUrl, fit: BoxFit.cover, width: double.infinity)
                                : Container(color: Colors.grey[300]),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shop.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.yellow, size: 16),
                                    Text(shop.rating.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Popular Items",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),

                buildFilterButton(() => showFilterSheet(), labelFromFilter(widget.selectedFilter)),
              ],
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (ctx, i) {
              final item = filteredItems[i];
              return GestureDetector(
                onTap: () => widget.onItemTap(item),
                child: Card(
                  color: const Color.fromARGB(255, 4, 3, 49),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, color: Colors.white),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.white),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                            Text("Rp${item.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(item.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
