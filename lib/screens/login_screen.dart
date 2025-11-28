import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/cart_entry.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final List<Shop> shops;
  final Function(Item) onAddToCart;
  final List<CartEntry> cart;
  final double Function() cartTotal;
  final Function(String, int) onChangeQty;
  final Future<void> Function() onReloadShops;
  final Future<void> Function() onLoginSuccess;
  final VoidCallback? reloadCart;

  const LoginScreen({
    required this.shops,
    required this.onAddToCart,
    required this.cart,
    required this.cartTotal,
    required this.onChangeQty,
    required this.onReloadShops,
    required this.onLoginSuccess,
    this.reloadCart,
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<List<Shop>> fetchShops() async {
    final shopSnap = await FirebaseFirestore.instance.collection('shops').get();
    List<Shop> loadedShops = [];

    for (var shopDoc in shopSnap.docs) {
      final itemsSnap = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopDoc.id)
          .collection('items')
          .get();

      final items = itemsSnap.docs
          .map((itemDoc) {
            final data = itemDoc.data();
            data['id'] = itemDoc.id;
            return Item.fromMap(data);
          })
          .toList();

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

    return loadedShops;
  }

  Future<List<Shop>> reloadShops() async {
    return await fetchShops();
  }

  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.FirebaseAuth.instance.signOut();

      final input = emailController.text.trim();
      final password = passwordController.text;

      if (input.isEmpty) {
        throw 'Please enter your username or email';
      }
      if (password.isEmpty) {
        throw 'Please enter your password';
      }

      String emailToUse = input;
      if (!input.contains('@')) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .get();
        if (querySnapshot.docs.isEmpty) {
          throw 'Username not found';
        }
        final userData = querySnapshot.docs.first.data();
        emailToUse = userData['email'];
      }

      final userCredential = await FirebaseAuth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailToUse, password: password);

      final userId = userCredential.user!.uid;

      // Fetch user by 'id' field instead of document ID
      final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();

        if (userQuery.docs.isEmpty) throw "User data not found in Firestore";

      final userData = userQuery.docs.first.data();
      final userRole = userData['role'];


      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('role', userRole.toString().trim().toLowerCase());
      await widget.onLoginSuccess();
    } on FirebaseAuth.FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Login failed: ${e.message}';
        if (e.code == 'user-not-found') {
          message = 'User not found';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.setString('role', 'guest');
    await widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Nimarket',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username/Email',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        OutlinedButton(
                          onPressed: _login,
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _continueAsGuest,
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
