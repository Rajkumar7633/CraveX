import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOpen = true;
  bool _busyMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isOpen ? Icons.store_rounded : Icons.storefront_rounded,
                  size: 16,
                  color: _isOpen ? const Color(0xFF2ECC71) : const Color(0xFFE23744),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isOpen ? const Color(0xFF2ECC71) : const Color(0xFFE23744),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeColor: const Color(0xFF2ECC71),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: _drawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              StatCard(title: "Today's Orders", value: '24', icon: Icons.receipt_long_rounded, color: Color(0xFFE23744)),
              StatCard(title: 'Revenue', value: '₹12,450', icon: Icons.currency_rupee_rounded, color: Color(0xFF2ECC71)),
              StatCard(title: 'Avg Rating', value: '4.4', icon: Icons.star_rounded, color: Color(0xFFFFB800)),
              StatCard(title: 'Pending', value: '3', icon: Icons.pending_actions_rounded, color: Color(0xFFE67E22)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Busy mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Busy Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: const Text('Pause new orders temporarily', style: TextStyle(fontSize: 13, color: Colors.grey)),
              value: _busyMode,
              onChanged: (v) => setState(() => _busyMode = v),
              activeColor: AppTheme.primaryRed,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Live orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
              ),
              TextButton(
                onPressed: () => context.push('/orders'),
                child: const Text('View All', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...MockData.restaurantOrders.take(3).map((o) => _orderCard(o)),
        ],
      ),
    );
  }

  Widget _orderCard(Order order) {
    Color statusColor = AppTheme.primaryRed;
    String statusLabel = 'New Order';
    
    if (order.status == AppOrderStatus.preparing) {
      statusColor = const Color(0xFFE67E22);
      statusLabel = 'Preparing';
    } else if (order.status == AppOrderStatus.ready) {
      statusColor = const Color(0xFF2ECC71);
      statusLabel = 'Ready';
    } else if (order.status == AppOrderStatus.pickedUp) {
      statusColor = const Color(0xFF3498DB);
      statusLabel = 'Picked Up';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.id.substring(order.id.length - 6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '10 min ago',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.shopping_bag_rounded, size: 16, color: Colors.grey),
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
            const SizedBox(height: 8),
            Text(
              order.items.map((i) => i.name).join(', '),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (order.status == AppOrderStatus.placed) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE23744)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Accept',
                      onPressed: () {},
                    ),
                  ),
                ] else if (order.status == AppOrderStatus.preparing) ...[
                  Expanded(
                    child: PrimaryButton(
                      text: 'Mark Ready',
                      onPressed: () {},
                    ),
                  ),
                ] else if (order.status == AppOrderStatus.ready) ...[
                  Expanded(
                    child: PrimaryButton(
                      text: 'Hand to Rider',
                      onPressed: () {},
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Drawer _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('Meghana Foods', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Partner Dashboard', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.receipt_long_rounded, 'Orders', () { Navigator.pop(context); context.push('/orders'); }),
          _drawerItem(Icons.restaurant_menu_rounded, 'Menu', () { Navigator.pop(context); context.push('/menu'); }),
          _drawerItem(Icons.analytics_rounded, 'Analytics', () { Navigator.pop(context); context.push('/analytics'); }),
          _drawerItem(Icons.star_rounded, 'Reviews', () { Navigator.pop(context); context.push('/reviews'); }),
          _drawerItem(Icons.local_offer_rounded, 'Promotions', () { Navigator.pop(context); context.push('/promotions'); }),
          _drawerItem(Icons.settings_rounded, 'Settings', () { Navigator.pop(context); context.push('/settings'); }),
          const Divider(height: 1),
          _drawerItem(Icons.logout_rounded, 'Logout', () => context.push('/login'), isDestructive: true),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFE23744) : const Color(0xFF1C1C1C)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? const Color(0xFFE23744) : const Color(0xFF1C1C1C))),
      onTap: onTap,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = const Color(0xFFE23744),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
