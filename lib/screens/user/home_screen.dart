import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/item.dart';
import '../../models/cart_entry.dart';
import 'shop_details_screen.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'orders_page.dart';
import '../../widgets/home_page_content.dart';
import '../../widgets/simple_item_search.dart';
import '../chat/chat_list_screen.dart';
import '../../services/chat_services.dart'; // Ensure this matches your filename

class UserHomeScreen extends StatefulWidget {
  final List<Shop> shops;
  final List<CartEntry> cart;
  final void Function(Item) onAddToCart;
  final double Function() cartTotal;
  final Function(String, int) onChangeQty;
  final bool isGuest;
  final Future<void> Function()? reloadCart;
  final Future<List<Shop>> Function()? reloadShops;
  final Future<void> Function()? onLogout;

  const UserHomeScreen({
    required this.shops,
    required this.onAddToCart,
    required this.cart,
    required this.cartTotal,
    required this.onChangeQty,
    this.isGuest = false,
    this.reloadCart,
    this.reloadShops,
    this.onLogout,
    super.key,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  late List<Shop> _shops;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _shops = widget.shops;
  }

  void _handleAddToCart(Item item) {
    widget.onAddToCart(item);
    if (mounted) setState(() {});
  }

  Future<void> _refreshData() async {
    try {
      if (widget.reloadShops != null) {
        final freshShops = await widget.reloadShops!();
        if (mounted) {
          setState(() {
            _shops = freshShops;
          });
        }
      }

      if (widget.reloadCart != null) {
        await widget.reloadCart!();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void _openShop(Shop shop) {
    if (widget.isGuest) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailsScreen(
          shop: shop,
          onAddToCart: _handleAddToCart,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onFilterChanged(String newFilter) {
    if (!mounted) return;
    setState(() {
      _selectedFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      RefreshIndicator(
        onRefresh: _refreshData,
        child: HomePageContent(
          shops: _shops,
          onShopTap: _openShop,
          onItemTap: widget.isGuest ? (_) {} : _handleAddToCart,
          selectedFilter: _selectedFilter,
          onFilterChanged: _onFilterChanged,
        ),
      ),

      widget.isGuest
          ? const Center(
              child: Text(
                "Please log in to access the cart",
                style: TextStyle(color: Colors.white),
              ),
            )
          : CartPage(
              cart: widget.cart,
              onChangeQty: widget.onChangeQty,
              total: widget.cartTotal(),
            ),

      OrdersPage(onReorderItem: _handleAddToCart),

      ProfilePage(
        shops: _shops,
        cart: widget.cart,
        onAddToCart: _handleAddToCart,
        cartTotal: widget.cartTotal,
        onChangeQty: widget.onChangeQty,
        onReloadShops: () async {
          if (widget.reloadShops != null) {
            await widget.reloadShops!();
            if (mounted) setState(() {});
          }
        },
        onLoginSuccess: () async {
          if (mounted) setState(() {});
        },
        reloadCart: widget.reloadCart,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: Container(
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
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (!mounted) return;
          setState(() => _selectedIndex = i);
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 0, 18, 217),
        elevation: 0,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (widget.cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      child: Text(
                        widget.cart.fold(0, (sum, entry) => sum + entry.qty)
                            .toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      
      floatingActionButton: _selectedIndex == 0 && !widget.isGuest
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- CHAT BUTTON WITH NOTIFICATION BADGE ---
                StreamBuilder<int>(
                  stream: ChatService().getTotalUnreadCount(),
                  builder: (context, snapshot) {
                    final int unreadCount = snapshot.data ?? 0;

                    return Stack(
                      clipBehavior: Clip.none, // Allows badge to hang over edge
                      children: [
                        FloatingActionButton(
                          heroTag: "chatBtn",
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 37, 0, 157),
                          child: const Icon(Icons.chat_bubble),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatListScreen(),
                              ),
                            );
                          },
                        ),
                        // Red Badge Logic
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                // --- SEARCH BUTTON ---
                FloatingActionButton(
                  heroTag: "searchBtn",
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromARGB(255, 37, 0, 157),
                  child: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: SimpleItemSearch(
                        widget.shops,
                        _handleAddToCart,
                        _openShop,
                        filter: _selectedFilter,
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}