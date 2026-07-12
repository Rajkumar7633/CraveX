import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:widgets/widgets.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _pollTimer;
  Order? _order;
  bool _isLoading = true;
  String? _error;

  static const _statusSteps = [
    AppOrderStatus.placed,
    AppOrderStatus.accepted,
    AppOrderStatus.preparing,
    AppOrderStatus.pickedUp,
    AppOrderStatus.onTheWay,
    AppOrderStatus.delivered,
  ];

  static const _statusLabels = {
    AppOrderStatus.placed: 'Order Placed',
    AppOrderStatus.accepted: 'Order Accepted',
    AppOrderStatus.preparing: 'Preparing your food',
    AppOrderStatus.pickedUp: 'Ready for pickup',
    AppOrderStatus.onTheWay: 'Out for delivery',
    AppOrderStatus.delivered: 'Delivered!',
    AppOrderStatus.cancelled: 'Order Cancelled',
  };

  static const _statusIcons = {
    AppOrderStatus.placed: Icons.receipt_long_rounded,
    AppOrderStatus.accepted: Icons.check_circle_rounded,
    AppOrderStatus.preparing: Icons.restaurant_rounded,
    AppOrderStatus.pickedUp: Icons.delivery_dining_rounded,
    AppOrderStatus.onTheWay: Icons.directions_bike_rounded,
    AppOrderStatus.delivered: Icons.celebration_rounded,
    AppOrderStatus.cancelled: Icons.cancel_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    // Poll every 10s for real-time status
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchOrder());
  }

  Future<void> _fetchOrder() async {
    try {
      final order = await OrderApi().getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
          _error = null;
        });
        // Stop polling when delivered or cancelled
        if (order.status == AppOrderStatus.delivered || order.status == AppOrderStatus.cancelled) {
          _pollTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not fetch order status';
        });
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1C)),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C))),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE23744)),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchOrder();
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFE23744)),
          const SizedBox(height: 16),
          Text('Fetching order status...', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFE23744)),
          const SizedBox(height: 16),
          const Text('Could not load order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() { _isLoading = true; _error = null; });
              _fetchOrder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final statusIndex = _statusSteps.indexOf(order.status).clamp(0, _statusSteps.length - 1);
    final isCancelled = order.status == AppOrderStatus.cancelled;
    final isDelivered = order.status == AppOrderStatus.delivered;
    final eta = order.estimatedDeliveryTime.difference(DateTime.now()).inMinutes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status hero card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCancelled
                  ? [const Color(0xFF666666), const Color(0xFF999999)]
                  : isDelivered
                      ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                      : [const Color(0xFFE23744), const Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isCancelled ? Colors.grey : isDelivered ? const Color(0xFF2ECC71) : const Color(0xFFE23744)).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                _statusIcons[order.status] ?? Icons.receipt_long_rounded,
                size: 56,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _statusLabels[order.status] ?? order.status,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (!isCancelled && !isDelivered)
                Text(
                  eta > 0 ? 'Arrives in ~$eta mins' : 'Arriving soon!',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                )
              else if (isDelivered)
                const Text('Your order has been delivered 🎉', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Status timeline
        if (!isCancelled) _buildTimeline(statusIndex),

        const SizedBox(height: 20),

        // Rider info (if assigned)
        if (order.riderName != null) _buildRiderCard(order),

        if (order.riderName != null) const SizedBox(height: 16),

        // Order details
        _buildOrderDetails(order),

        const SizedBox(height: 16),

        // Cancel button (only if placed or accepted)
        if (!isDelivered && !isCancelled &&
            (order.status == AppOrderStatus.placed || order.status == AppOrderStatus.accepted))
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _cancelOrder(order.id),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE23744)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel Order', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeline(int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 16),
          ...List.generate(_statusSteps.length, (i) {
            final isDone = i <= currentIndex;
            final isCurrent = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFE23744) : const Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : Icons.circle,
                          color: Colors.white,
                          size: isDone ? 16 : 8,
                        ),
                      ),
                      if (i < _statusSteps.length - 1)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 2,
                          height: 24,
                          color: i < currentIndex ? const Color(0xFFE23744) : const Color(0xFFE0E0E0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _statusLabels[_statusSteps[i]] ?? _statusSteps[i],
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? const Color(0xFFE23744) : (isDone ? const Color(0xFF1C1C1C) : Colors.grey),
                        fontSize: isCurrent ? 14 : 13,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE23744),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Delivery Partner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEF),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFFE23744), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.riderName ?? 'Rider', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (order.riderPhone != null)
                      Text(order.riderPhone!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              if (order.riderPhone != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE23744),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                VegIndicator(isVeg: item.isVeg),
                const SizedBox(width: 10),
                Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                Text('x${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                Text('₹${item.lineTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('₹${order.total.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFE23744))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await OrderApi().cancelOrder(orderId);
        _fetchOrder();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not cancel order'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
