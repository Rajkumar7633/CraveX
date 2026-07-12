import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:widgets/widgets.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const RestaurantDetailScreen({super.key, required this.id});
  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _vegOnly = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addToCart(MenuItem item, String restaurantId) {
    ref.read(cartProvider.notifier).addItem(CartItem(
      menuItemId: item.id,
      restaurantId: restaurantId,
      name: item.name,
      price: item.price,
      quantity: 1,
      isVeg: item.isVeg,
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('${item.name} added to cart'),
        ],
      ),
      backgroundColor: const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(widget.id));
    final menuAsync = ref.watch(menuProvider(widget.id));
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: restaurantAsync.when(
        loading: () => const _RestaurantShimmer(),
        error: (err, _) => _errorBody(context),
        data: (restaurant) => _buildBody(context, restaurant, menuAsync, cartItems, cartNotifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Restaurant restaurant,
    AsyncValue<Map<String, List<MenuItem>>> menuAsync,
    List<CartItem> cartItems,
    CartNotifier cartNotifier,
  ) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero app bar
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                  ]),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1C1C1C)),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      color: const Color(0xFFF0F0F0),
                      child: restaurant.coverImage != null
                          ? Image.network(restaurant.coverImage!, fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (_, __, ___) => _placeholder(restaurant.name))
                          : _placeholder(restaurant.name),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Restaurant info
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
                          ),
                        ),
                        _RatingBadge(rating: restaurant.rating),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(restaurant.cuisines.join(' • '),
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.access_time_rounded, label: '${restaurant.deliveryTime} min'),
                        const SizedBox(width: 10),
                        _InfoChip(
                          icon: Icons.delivery_dining_rounded,
                          label: restaurant.deliveryFee == 0 ? 'Free Delivery' : '₹${restaurant.deliveryFee.toInt()}',
                          color: restaurant.deliveryFee == 0 ? const Color(0xFF2ECC71) : null,
                        ),
                        const SizedBox(width: 10),
                        _InfoChip(icon: Icons.people_outline_rounded, label: '₹${restaurant.costForTwo} for 2'),
                      ],
                    ),
                    if (restaurant.hasOffer && restaurant.offerText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE23744).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: Color(0xFFE23744), size: 16),
                            const SizedBox(width: 8),
                            Text(restaurant.offerText!, style: const TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: Color(0xFF2ECC71), size: 16),
                        const SizedBox(width: 6),
                        const Text('Veg Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        Switch(
                          value: _vegOnly,
                          onChanged: (v) => setState(() => _vegOnly = v),
                          activeColor: const Color(0xFF2ECC71),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Menu
            menuAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate((_, __) => const _MenuItemShimmer(), childCount: 5),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Failed to load menu. Please try again.', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              data: (menuMap) {
                final allWidgets = <Widget>[];
                for (final entry in menuMap.entries) {
                  var items = entry.value;
                  if (_vegOnly) items = items.where((i) => i.isVeg).toList();
                  if (items.isEmpty) continue;

                  // Category header
                  allWidgets.add(Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
                    ),
                  ));
                  for (final item in items) {
                    final qty = cartItems.where((ci) => ci.menuItemId == item.id).fold(0, (sum, ci) => sum + ci.quantity);
                    allWidgets.add(_MenuItemCard(
                      item: item,
                      quantity: qty,
                      onAdd: () => _addToCart(item, restaurant.id),
                      onIncrement: () => ref.read(cartProvider.notifier).updateQuantity(item.id, qty + 1),
                      onDecrement: () => ref.read(cartProvider.notifier).updateQuantity(item.id, qty - 1),
                    ));
                  }
                }

                if (allWidgets.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('🥗', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            const Text('No menu items available', style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => allWidgets[i],
                    childCount: allWidgets.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Cart FAB
        if (cartItems.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => context.push('/cart'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE23744), Color(0xFFFF6B6B)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFFE23744).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('${cartItems.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    Text('₹${cartNotifier.total.toInt()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(String name) => Container(
    color: const Color(0xFFF0F0F0),
    child: Center(child: Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey[300])),
  );

  Widget _errorBody(BuildContext context) => Scaffold(
    appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop())),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Failed to load restaurant', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => ref.invalidate(restaurantDetailProvider(widget.id)), child: const Text('Retry')),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
// Menu Item Card
// ─────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veg indicator
                VegIndicator(isVeg: item.isVeg),
                const SizedBox(height: 6),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.description, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Text('₹${item.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1C1C1C))),
                if (item.isRecommended) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
                    child: const Text('⭐ Bestseller', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Image + Add button
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl != null
                    ? Image.network(item.imageUrl!, width: 90, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                    : _imgPlaceholder(),
              ),
              const SizedBox(height: 8),
              // Quantity control
              if (quantity == 0)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE23744)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ADD', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE23744),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onDecrement,
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, color: Colors.white, size: 16)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      GestureDetector(
                        onTap: onIncrement,
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, color: Colors.white, size: 16)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 90,
    height: 80,
    color: const Color(0xFFF0F0F0),
    child: const Icon(Icons.fastfood_rounded, color: Color(0xFFD0D0D0), size: 32),
  );
}

// ─────────────────────────────────────────────
// Support Widgets
// ─────────────────────────────────────────────
class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});
  @override
  Widget build(BuildContext context) {
    final color = rating >= 4.0 ? const Color(0xFF2ECC71) : rating >= 3.0 ? const Color(0xFFF39C12) : const Color(0xFFE23744);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Shimmer for restaurant detail loading
class _RestaurantShimmer extends StatelessWidget {
  const _RestaurantShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          Container(height: 220, color: Colors.white),
          const SizedBox(height: 8),
          ...List.generate(4, (_) => Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          )),
        ],
      ),
    );
  }
}

class _MenuItemShimmer extends StatelessWidget {
  const _MenuItemShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
