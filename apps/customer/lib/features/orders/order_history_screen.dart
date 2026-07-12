import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1C1C1C)),
            onPressed: () => ref.invalidate(myOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => const _OrderShimmer(),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Could not load orders', style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(myOrdersProvider),
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
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFD0D0D0)),
                  ),
                  const SizedBox(height: 20),
                  const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Your order history will appear here', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE23744),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Order Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            color: const Color(0xFFE23744),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) => _OrderCard(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final statusColor = _statusColor(status);
    final isActive = status != AppConstants.orderDelivered && status != AppConstants.orderCancelled;

    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFFE23744), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1C1C1C)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.total.toInt()}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Items preview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                order.items.take(2).map((i) => i.name).join(', ') + (order.items.length > 2 ? ' +${order.items.length - 2} more' : ''),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 20, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (isActive)
                    _ActionButton(
                      label: 'Track Order',
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFFE23744),
                      onTap: () => context.push('/order/${order.id}'),
                    )
                  else
                    _ActionButton(
                      label: 'Reorder',
                      icon: Icons.replay_rounded,
                      color: const Color(0xFF1C1C1C),
                      onTap: () {/* Reorder logic */},
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'placed': return const Color(0xFF3498DB);
      case 'accepted': return const Color(0xFF9B59B6);
      case 'preparing': return const Color(0xFFE67E22);
      case 'ready': return const Color(0xFF27AE60);
      case 'picked_up':
      case 'on_the_way': return const Color(0xFF2ECC71);
      case 'delivered': return const Color(0xFF27AE60);
      case 'cancelled': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'placed': return 'Order Placed';
      case 'accepted': return 'Accepted';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready';
      case 'picked_up': return 'Picked Up';
      case 'on_the_way': return 'On the Way';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _OrderShimmer extends StatelessWidget {
  const _OrderShimmer();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
