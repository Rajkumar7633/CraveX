import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'restaurant_provider.dart';
import 'location_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartCount = cartItems.length;
    final cartTotal = cartNotifier.total;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _tab,
        children: const [
          _HomeTab(),
          _SearchTab(),
          _OrdersTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
      floatingActionButton: cartCount == 0
          ? null
          : GestureDetector(
              onTap: () => context.push('/cart'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE23744), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23744).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '$cartCount item${cartCount > 1 ? 's' : ''} • ₹${cartTotal.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Nav
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.search_rounded, label: 'Search', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEEEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFE23744) : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFE23744) : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();
  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  bool _vegOnly = false;
  int _selectedCategory = 0;

  static const _categories = [
    {'name': 'All', 'icon': '🍽️'},
    {'name': 'Biryani', 'icon': '🍛'},
    {'name': 'Pizza', 'icon': '🍕'},
    {'name': 'Chinese', 'icon': '🥡'},
    {'name': 'Burger', 'icon': '🍔'},
    {'name': 'Desserts', 'icon': '🍰'},
    {'name': 'South Indian', 'icon': '🥘'},
    {'name': 'Healthy', 'icon': '🥗'},
  ];

  static const _banners = [
    {'title': '50% OFF', 'subtitle': 'On your first order • Code: FIRST50', 'gradient': [0xFFE23744, 0xFFFF6B6B]},
    {'title': 'Free Delivery', 'subtitle': 'On orders above ₹199', 'gradient': [0xFF1C1C1C, 0xFF3D3D3D]},
    {'title': 'CraveX Gold', 'subtitle': 'Extra 10% off everywhere', 'gradient': [0xFFB8860B, 0xFFD4A017]},
  ];

  // Pre-computed gradient colors for better performance
  static final _bannerGradients = _banners.map((b) {
    final colors = (b['gradient'] as List).map((c) => Color(c as int)).toList();
    return LinearGradient(colors: colors);
  }).toList();

  @override
  void initState() {
    super.initState();
    // Request location permission after a delay to avoid blocking UI
    Future.microtask(() => _requestLocationPermission());
  }

  Future<void> _requestLocationPermission() async {
    try {
      await ref.read(locationProvider.notifier).requestLocationPermission();
    } catch (e) {
      // Silently handle permission errors to avoid UI blocking
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);
    final locationState = ref.watch(locationProvider);
    final authState = ref.watch(authProvider);

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFE23744), size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivering to', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      GestureDetector(
                        onTap: () => _requestLocationPermission(),
                        child: Row(
                          children: [
                            Text(
                              locationState.hasPermission && locationState.currentPosition != null
                                  ? 'Current Location'
                                  : 'Set Location',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C)),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (authState.isAuthenticated)
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFEEEF),
                    child: Text(
                      authState.user?.name.isNotEmpty == true 
                          ? authState.user!.name[0].toUpperCase() 
                          : 'U',
                      style: const TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => context.go('/onboarding'),
                    icon: const Icon(Icons.login_rounded, color: Color(0xFFE23744), size: 16),
                    label: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFFE23744),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1C1C1C)),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      'Search restaurants, dishes...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.mic_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pure Veg toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _vegOnly ? const Color(0xFF2ECC71) : Colors.transparent,
                    border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: _vegOnly ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
                ),
                const SizedBox(width: 8),
                const Text('Pure Veg', style: TextStyle(fontWeight: FontWeight.w600)),
                Switch(
                  value: _vegOnly,
                  onChanged: (v) => setState(() => _vegOnly = v),
                  activeColor: const Color(0xFF2ECC71),
                ),
              ],
            ),
          ),
        ),

        // Banner carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: PageView.builder(
              itemCount: _banners.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (_, i) {
                final b = _banners[i];
                final gradient = _bannerGradients[i];
                final colors = (b['gradient'] as List).map((c) => Color(c as int)).toList();
                return Container(
                  margin: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(b['subtitle'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = i == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE23744) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFFE23744) : const Color(0xFFE0E0E0),
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: const Color(0xFFE23744).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c['icon'] as String, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          c['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : const Color(0xFF1C1C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Section title
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Restaurants near you',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
            ),
          ),
        ),

        // Restaurant list
        if (restaurantState.isLoading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _RestaurantShimmerCard(),
              childCount: 4,
            ),
          )
        else if (restaurantState.hasError)
          SliverToBoxAdapter(
            child: _ErrorWidget(
              message: restaurantState.errorMessage ?? 'Could not load restaurants',
              onRetry: () => ref.read(restaurantProvider.notifier).refresh(),
            ),
          )
        else
          _buildRestaurantList(restaurantState.restaurants),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildRestaurantList(List<Restaurant> restaurants) {
    var filtered = restaurants;
    if (_vegOnly) filtered = filtered.where((r) => r.isPureVeg).toList();
    
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  restaurants.isEmpty
                      ? 'No restaurants available right now'
                      : 'No vegetarian restaurants nearby',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _RestaurantCard(restaurant: filtered[i]),
        childCount: filtered.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Restaurant Card
// ─────────────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    color: const Color(0xFFF0F0F0),
                    child: restaurant.coverImage != null
                        ? Image.network(restaurant.coverImage!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage())
                        : _placeholderImage(),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                        ),
                      ),
                    ),
                  ),
                  // Delivery time badge
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF1C1C1C)),
                          const SizedBox(width: 4),
                          Text('${restaurant.deliveryTime} min',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  // Offer badge
                  if (restaurant.hasOffer && restaurant.offerText != null)
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE23744),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.offerText!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  // Veg badge
                  if (restaurant.isPureVeg)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PURE VEG',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _ratingColor(restaurant.rating),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 3),
                            Text(restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisines.join(' • '),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.deliveryFee == 0 ? 'Free Delivery' : '₹${restaurant.deliveryFee.toInt()} delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: restaurant.deliveryFee == 0 ? const Color(0xFF2ECC71) : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('₹${restaurant.costForTwo} for two',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_rounded, size: 48, color: Color(0xFFD0D0D0)),
            const SizedBox(height: 4),
            Text(restaurant.name.substring(0, restaurant.name.length.clamp(0, 12)),
                style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF2ECC71);
    if (rating >= 3.0) return const Color(0xFFF39C12);
    return const Color(0xFFE23744);
  }
}

// ─────────────────────────────────────────────
// Shimmer Loading Card
// ─────────────────────────────────────────────
class _RestaurantShimmerCard extends StatelessWidget {
  const _RestaurantShimmerCard();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 170, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(18)))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 180, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                  Container(height: 12, width: 120, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                  Container(height: 12, width: 200, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error Widget
// ─────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23744),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// Tab wrappers
class _SearchTab extends StatelessWidget {
  const _SearchTab();
  @override
  Widget build(BuildContext context) => const SearchScreen();
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();
  @override
  Widget build(BuildContext context) => const OrderHistoryScreen();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
