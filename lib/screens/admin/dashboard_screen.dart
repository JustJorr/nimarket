import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shop.dart';
import '../../models/item.dart';
import 'manage_shops_screen.dart';
import 'manage_inventory_screen.dart';
import 'manage_orders_screen.dart';

class AdminDashboard extends StatefulWidget {
    final List<Shop> shops;
    final Future<void> Function()? onLogout;

  const AdminDashboard({
    super.key,
    required this.shops,
    this.onLogout,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Shop> shops = [];
  bool loading = true;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    loadShops();
    loadTotalUsers();
  }

  Future<void> loadShops() async {
    setState(() => loading = true);

    List<Shop> loadedShops = [];

    final shopSnap = await FirebaseFirestore.instance.collection('shops').get();

    for (var shopDoc in shopSnap.docs) {
      final itemsSnap = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopDoc.id)
          .collection('items')
          .get();

      final items = itemsSnap.docs.map((i) => Item.fromMap(i.data())).toList();

      loadedShops.add(
        Shop(
          id: shopDoc.id,
          name: shopDoc['name'] ?? '',
          description: shopDoc['description'] ?? '',
          bannerUrl: shopDoc['bannerUrl'] ?? '',
          active: shopDoc['active'] ?? true,
          items: items,

        ),
      );
    }

    setState(() {
      shops = loadedShops;
      loading = false;
    });
  }

  Future<void> loadTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      totalUsers = snapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 7, 12, 156),
        foregroundColor: Colors.amber,
      ),
      drawer: Drawer(
        child: Container(
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
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color.fromARGB(255, 37, 0, 157)),
                child: Text("Nimarket Admin",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.white),
                title: const Text("Manage Shops", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageShopsScreen(
                        shops: shops,
                        onShopAdded: (shop) {},
                        onRefresh: () async {
                          await loadShops();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory, color: Colors.white),
                title: const Text("Manage Inventory",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageInventoryScreen(
                        shops: shops,
                        onItemAdded: (_) {},
                        onRefresh: () async {
                          await loadShops();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.white),
                title: const Text(
                  "Manage Orders",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageOrdersScreen(),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text("Logout", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  if (widget.onLogout != null) {
                    await widget.onLogout!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadShops,
              child: Container(
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
                  child: GridView.count(
                    crossAxisCount: 2,
                    children: [
                      _dashboardCard("Total Shops", shops.length.toString(),
                          Icons.store, Colors.amber),
                      _dashboardCard(
                        "Total Items",
                        shops.fold(0, (sum, s) => sum + s.items.length).toString(),
                        Icons.inventory,
                        Colors.amber,
                      ),
                      _dashboardCard("Total Users", totalUsers.toString(),
                          Icons.people, Colors.amber),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _dashboardCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
