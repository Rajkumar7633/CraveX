import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _vegOnly = false;
  final _quantities = <String, int>{};

  Restaurant get restaurant =>
      MockData.restaurants.firstWhere((r) => r.id == widget.id, orElse: () => MockData.restaurants.first);

  List<MenuItem> get items {
    var list = MockData.menuItems(widget.id);
    if (_vegOnly) list = list.where((i) => i.isVeg).toList();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _addToCart(MenuItem item) {
    setState(() => _quantities[item.id] = (_quantities[item.id] ?? 0) + 1);
    CartService().addItem(CartItem(
      menuItemId: item.id,
      restaurantId: widget.id,
      name: item.name,
      price: item.price,
      quantity: 1,
      isVeg: item.isVeg,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(restaurant.name),
              background: Container(color: Colors.grey[300], child: const Icon(Icons.restaurant, size: 64)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ratingBadge(restaurant.rating),
                      const SizedBox(width: 8),
                      Text('${restaurant.reviewCount} ratings'),
                      const Spacer(),
                      Text('₹${restaurant.costForTwo} for two'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant.cuisines.join(' • '), style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      Text(' ${restaurant.deliveryTime} mins'),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16),
                      Text(' ${restaurant.distanceKm} km'),
                    ],
                  ),
                  if (restaurant.hasOffer) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: AppTheme.primaryRed),
                          const SizedBox(width: 8),
                          Text(restaurant.offerText ?? 'Special offer available'),
                        ],
                      ),
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Veg only'),
                    value: _vegOnly,
                    onChanged: (v) => setState(() => _vegOnly = v),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Menu'), Tab(text: 'Reviews'), Tab(text: 'Info')],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => MenuItemTile(
                    item: items[i],
                    quantity: _quantities[items[i].id] ?? 0,
                    onAdd: () => _addToCart(items[i]),
                  ),
                ),
                _ReviewsTab(),
                _InfoTab(restaurant: restaurant),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => context.push('/cart'),
                  child: Text('View Cart • ${cart.items.length} items • ₹${cart.total.toInt()}'),
                ),
              ),
            ),
    );
  }

  Widget _ratingBadge(double rating) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Icon(Icons.star, color: Colors.white, size: 14),
          ],
        ),
      );
}

class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(3, (i) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('U${i + 1}')),
              title: Row(
                children: [
                  Text('User ${i + 1}'),
                  const Spacer(),
                  ...List.generate(5, (s) => Icon(Icons.star, size: 14, color: s < 4 ? Colors.amber : Colors.grey[300])),
                ],
              ),
              subtitle: const Text('Great food and fast delivery! Highly recommended.'),
            ),
          )),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Restaurant restaurant;
  const _InfoTab({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(leading: const Icon(Icons.location_on), title: const Text('Address'), subtitle: Text(restaurant.address)),
        ListTile(leading: const Icon(Icons.verified), title: const Text('FSSAI License'), subtitle: Text(restaurant.fssaiLicense ?? 'N/A')),
        ListTile(leading: const Icon(Icons.access_time), title: const Text('Timings'), subtitle: const Text('11:00 AM - 11:00 PM')),
        ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: const Text('+91 80 1234 5678')),
      ],
    );
  }
}
