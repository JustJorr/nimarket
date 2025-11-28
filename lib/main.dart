import 'package:flutter/material.dart';
import 'models/shop.dart';
import 'models/item.dart';
import 'models/cart_entry.dart';
import 'screens/login_screen.dart';
import 'screens/user/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://fshqsxjzcjfanmvtatbo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzaHFzeGp6Y2pmYW5tdnRhdGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NTgxNTEsImV4cCI6MjA3OTEzNDE1MX0.oQg-zOMtn98OPzDIGDNvTxjLds_ufaHxMlTNGnKatBY',
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  List<Shop> shops = [];
  List<CartEntry> cart = [];
  String? userId;
  String? role;
  bool isLoggedIn = false;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> onLoginSuccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      role = prefs.getString('role')?.toString().trim().toLowerCase();

      print('LOGIN SUCCESS: userId=$userId role=$role');

      if (userId == null && role == null) {
        print('ERROR: No userId or role found after login!');
        return;
      }
      await _loadShopsFromFirestore();
      if (role != 'guest') {
        await _loadCartFromFirestore();
      }
      if (mounted) {
        setState(() {
          isLoggedIn = true;
        });
      }
    } catch (e) {
      print('Error in onLoginSuccess: $e');
    }
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    role = prefs.getString('role')?.toString().trim().toLowerCase();

    print('INIT: stored userId=$userId role=$role');

    if (role == 'guest') {
      await _loadShopsFromFirestore();
      isLoggedIn = true;
    } else if (userId != null && role != null) {
    await _loadShopsFromFirestore();
    await _loadCartFromFirestore();
      if (mounted) {
        setState(() {
          isLoggedIn = true;
        });
      }
    }
  }

  Future<List<Shop>> _loadShopsFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('shops').get();
    List<Shop> loadedShops = [];

    for (var doc in snapshot.docs) {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .doc(doc.id)
          .collection('items')
          .get();

      final items = itemsSnapshot.docs.map((i) {
        final data = Map<String, dynamic>.from(i.data());
        data['id'] = i.id;
        data['shopId'] = doc.id;
        return Item.fromMap(data);
      }).toList();

      loadedShops.add(Shop(
        id: doc.id,
        name: doc['name'] ?? '',
        description: doc['description'] ?? '',
        bannerUrl: doc['bannerUrl'] ?? '',
        items: items,
        active: doc['active'] ?? true,
        rating: (doc.data()['rating'] as num?)?.toDouble() ?? 0.0,
        ratings: (doc.data()['ratings'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      ));
    }

    if (mounted) {
      setState(() {
        shops = loadedShops;
      });
    }

    return loadedShops;
  }

  Future<void> _loadCartFromFirestore() async {
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final loadedCart = snapshot.docs.map((doc) => CartEntry.fromMap(doc.data())).toList();

      if (mounted) {
        setState(() {
          cart.clear();
          for (var entry in loadedCart) {
            final existing = cart.where((e) => e.item.id == entry.item.id).toList();
            if (existing.isNotEmpty) {
              existing.first.qty += entry.qty;
            } else {
              cart.add(entry);
            }
          }
        });
      }
    }
  }

  Future<void> _saveCartToFirestore() async {
    if (userId != null) {
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance.collection('users').doc(userId!).collection('cart');

      final existingDocs = await cartRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var entry in cart) {
        batch.set(cartRef.doc(), entry.toMap());
      }

      await batch.commit();
    }
  }

  void addToCart(Item item) {
    final newCart = List<CartEntry>.from(cart);
    final existing = newCart.where((c) => c.item.id == item.id).toList();
    if (existing.isNotEmpty) {
      existing.first.qty += 1;
    } else {
      newCart.add(CartEntry(item: item, qty: 1));
    }
    setState(() {
      cart = newCart;
    });
    _saveCartToFirestore();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${item.name} is added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void changeQty(String id, int qty) {
    setState(() {
      final entry = cart.firstWhere((e) => e.item.id == id);
      if (qty > 0) {
        entry.qty = qty;
      } else {
        cart.remove(entry);
      }
    });
    _saveCartToFirestore();
  }

  double cartTotal() => cart.fold(0.0, (t, e) => t + e.item.price * e.qty);

  Future<void> reloadCart() async {
    await _loadCartFromFirestore();
  }

  Future<void> logout() async {
    print('LOGOUT CALLED');
    
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('role');
    
    // Clear state and force rebuild
    if (mounted) {
      setState(() {
        userId = null;
        role = null;
        isLoggedIn = false;
        cart = [];
        shops = [];
      });
    }
    
    print('LOGOUT COMPLETE: isLoggedIn=$isLoggedIn, role=$role');
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD: isLoggedIn=$isLoggedIn, role=$role');
    
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Nimarket',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
      ),
      home: !isLoggedIn
          ? LoginScreen(
              shops: shops,
              onAddToCart: addToCart,
              cart: cart,
              cartTotal: cartTotal,
              onChangeQty: changeQty,
              onReloadShops: () async {
                await _loadShopsFromFirestore();
              },
              onLoginSuccess: onLoginSuccess,
              reloadCart: reloadCart,
            )
          : _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    final roleNormalized = role?.toLowerCase();
    
    switch (roleNormalized) {
      case 'admin':
        return AdminDashboard(
          shops: shops,
          onLogout: logout,
        );
      case 'user':
      case 'student':
      case 'customer':
        return UserHomeScreen(
          shops: shops,
          onAddToCart: addToCart,
          cart: cart,
          cartTotal: cartTotal,
          onChangeQty: changeQty,
          isGuest: false,
          reloadCart: reloadCart,
          reloadShops: _loadShopsFromFirestore,
          onLogout: logout,  // Pass logout function
        );
      case 'guest':
        return UserHomeScreen(
          shops: shops,
          onAddToCart: addToCart,
          cart: cart,
          cartTotal: cartTotal,
          onChangeQty: changeQty,
          isGuest: true,
          reloadCart: reloadCart,
          reloadShops: _loadShopsFromFirestore,
          onLogout: logout,  // Pass logout function
        );
      default:
        return UserHomeScreen(
          shops: shops,
          onAddToCart: addToCart,
          cart: cart,
          cartTotal: cartTotal,
          onChangeQty: changeQty,
          isGuest: false,
          reloadShops: () => _loadShopsFromFirestore(),
          reloadCart: reloadCart,
          onLogout: logout,  // Pass logout function
        );
    }
  }
}