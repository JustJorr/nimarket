import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import '../../models/shop.dart';
import '../../models/cart_entry.dart';
import '../../theme.dart';

class ProfilePage extends StatefulWidget {
  final List<Shop> shops;
  final List<CartEntry> cart;
  final Function(Item) onAddToCart;
  final double Function() cartTotal;
  final Function(String, int) onChangeQty;
  final Future<void> Function() onReloadShops;
  final Future<void> Function() onLoginSuccess;
  final Future<void> Function()? reloadCart;
  final Future<void> Function()? onLogout;  // Add this

  const ProfilePage({
    super.key,
    required this.shops,
    required this.cart,
    required this.onAddToCart,
    required this.cartTotal,
    required this.onChangeQty,
    required this.onReloadShops,
    required this.onLoginSuccess,
    this.reloadCart,
    this.onLogout,  // Add this
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ThemeData _selectedTheme = navyTheme;

  Future<void> _logout(BuildContext context) async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
      
      // Show message after logout
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged out successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _selectedTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.amber,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // User username and email
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').where('id', isEqualTo: user?.uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text(
                        user?.email ?? "Guest",
                        style: TextStyle(color: _selectedTheme.primaryColor, fontSize: 18),
                      );
                    }
                    final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final username = userData['username'] ?? 'Unknown';
                    final email = userData['email'] ?? user?.email ?? 'Unknown';
                    return Column(
                      children: [
                        Text(
                          username,
                          style: TextStyle(color: _selectedTheme.primaryColor, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          email,
                          style: TextStyle(color: _selectedTheme.primaryColor, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Settings buttons: Theme dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Theme',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      onSelected: (value) {
                        setState(() {
                          if (value == 'Navy') {
                            _selectedTheme = navyTheme;
                          } else if (value == 'Bright') {
                            _selectedTheme = brightTheme;
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Navy',
                          child: Text('Navy (Default)'),
                        ),
                        const PopupMenuItem(
                          value: 'Bright',
                          child: Text('Bright'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Logout button
                ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}