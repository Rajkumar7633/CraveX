import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await OrderApi().acceptOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted'),
          backgroundColor: Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(hintText: 'Reason for rejection'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'Rejected'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (reason != null) {
      try {
        await OrderApi().rejectOrder(orderId, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Color(0xFFE23744),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject order: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, AppOrderStatus status) async {
    try {
      await OrderApi().updateOrderStatus(orderId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as ${AppOrderStatus.labels[status]}'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildOrderList(AppOrderStatus.placed),
          _buildOrderList(AppOrderStatus.preparing),
          _buildOrderList(AppOrderStatus.ready),
          _buildOrderList(AppOrderStatus.delivered),
        ],
      ),
    );
  }

  Widget _buildOrderList(AppOrderStatus status) {
    final orders = MockData.restaurantOrders.where((o) => o.status == status).toList();
    
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${AppOrderStatus.labels[status]} orders',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: orders.map((o) => _orderCard(o)).toList(),
    );
  }

  Widget _orderCard(Order order) {
    Color statusColor = AppTheme.primaryRed;
    if (order.status == AppOrderStatus.preparing) statusColor = const Color(0xFFE67E22);
    if (order.status == AppOrderStatus.ready) statusColor = const Color(0xFF2ECC71);
    if (order.status == AppOrderStatus.delivered) statusColor = const Color(0xFF3498DB);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 24),
        ),
        title: Row(
          children: [
            Text(
              '#${order.id.substring(order.id.length - 6).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppOrderStatus.labels[order.status] ?? order.status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '10 min ago',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.shopping_bag_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '₹${order.total.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryRed),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                VegIndicator(isVeg: item.isVeg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (item.variant != null) Text(item.variant!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (item.addOns != null && item.addOns!.isNotEmpty)
                        Text('Add-ons: ${item.addOns!.join(', ')}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${item.quantity}x ₹${item.lineTotal.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          )),
          if (order.specialInstructions != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_rounded, color: AppTheme.primaryRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.specialInstructions!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print KOT'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Spacer(),
              if (order.status == AppOrderStatus.placed) ...[
                OutlinedButton(
                  onPressed: () => _rejectOrder(order.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE23744)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: 'Accept',
                  onPressed: () => _acceptOrder(order.id),
                ),
              ] else if (order.status == AppOrderStatus.preparing) ...[
                PrimaryButton(
                  text: 'Mark Ready',
                  onPressed: () => _updateOrderStatus(order.id, AppOrderStatus.ready),
                ),
              ] else if (order.status == AppOrderStatus.ready) ...[
                PrimaryButton(
                  text: 'Hand to Rider',
                  onPressed: () => _updateOrderStatus(order.id, AppOrderStatus.pickedUp),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
