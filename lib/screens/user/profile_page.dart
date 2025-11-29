import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import '../../models/shop.dart';
import '../../models/cart_entry.dart';

class ProfilePage extends StatefulWidget {
  final List<Shop> shops;
  final List<CartEntry> cart;
  final Function(Item) onAddToCart;
  final double Function() cartTotal;
  final Function(String, int) onChangeQty;
  final Future<void> Function() onReloadShops;
  final Future<void> Function() onLoginSuccess;
  final Future<void> Function()? reloadCart;
  final Future<void> Function()? onLogout;

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
    this.onLogout, 
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Future<void> _logout(BuildContext context) async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
      
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
      // Applied the standard Dark Blue Gradient
      body: Container(
        width: double.infinity,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                // 1. Profile Picture
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber, // Border color
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Color.fromARGB(255, 4, 3, 49),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // 2. User Details (FutureBuilder)
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('id', isEqualTo: user?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(color: Colors.amber);
                    }
                    
                    String username = "Guest";
                    String email = user?.email ?? "No Email";

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      username = userData['username'] ?? 'Unknown';
                      email = userData['email'] ?? email;
                    }

                    return Column(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 16
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),
                const Divider(color: Colors.white24),
                const SizedBox(height: 40),

                // 3. Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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