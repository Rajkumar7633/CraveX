import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _pureVegMode = false;
  final _favorites = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(
            pureVegMode: _pureVegMode,
            onPureVegToggle: (v) => setState(() => _pureVegMode = v),
            favorites: _favorites,
            onFavorite: (id) => setState(() {
              _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
            }),
          ),
          const _SearchTab(),
          const _OrdersTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: CartService().isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              backgroundColor: AppTheme.primaryRed,
              icon: const Icon(Icons.shopping_cart),
              label: Text('${CartService().items.length} items • ₹${CartService().total.toInt()}'),
            ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final bool pureVegMode;
  final ValueChanged<bool> onPureVegToggle;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;

  const _HomeTab({
    required this.pureVegMode,
    required this.onPureVegToggle,
    required this.favorites,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    var restaurants = MockData.restaurants;
    if (pureVegMode) restaurants = restaurants.where((r) => r.isPureVeg).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivering to', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryRed, size: 16),
                  const SizedBox(width: 4),
                  Text(MockData.addresses.first.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
            IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.push('/cart')),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search restaurants, dishes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SwitchListTile(
            title: const Text('Pure Veg Mode'),
            subtitle: const Text('Show only vegetarian restaurants'),
            value: pureVegMode,
            onChanged: onPureVegToggle,
            activeThumbColor: AppTheme.vegGreen,
          ),
        ),
        SliverToBoxAdapter(child: _BannerCarousel()),
        SliverToBoxAdapter(child: _CategoryRow()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Restaurants near you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => RestaurantCard(
              restaurant: restaurants[i],
              isFavorite: favorites.contains(restaurants[i].id),
              onFavorite: () => onFavorite(restaurants[i].id),
              onTap: () => context.push('/restaurant/${restaurants[i].id}'),
            ),
            childCount: restaurants.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        itemCount: MockData.banners.length,
        itemBuilder: (_, i) {
          final b = MockData.banners[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(b['color'] as int),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(b['title'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(b['subtitle'] as String, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MockData.categories.length,
        itemBuilder: (_, i) {
          final c = MockData.categories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(c['icon'] as String, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 4),
                Text(c['name'] as String, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return const SearchScreen();
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const OrderHistoryScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
