import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Role portal — shown when a restaurant owner, rider, or admin logs in.
/// Provides their dashboard tools directly inside the app.
class RolePortalScreen extends ConsumerWidget {
  const RolePortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = user.userType;
    final config = _getRoleConfig(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: config.color,
            leading: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront_rounded, color: Colors.white),
                tooltip: 'Browse as Customer',
                onPressed: () => context.go('/home'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [config.color, config.color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: Icon(config.icon, color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, ${user.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          config.roleLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),
                // Quick stats row
                _buildStatsRow(role),
                const SizedBox(height: 20),
                // Menu grid
                Text(
                  'Dashboard',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(context, ref, role, config),
                const SizedBox(height: 24),
                // Recent activity
                _buildRecentActivity(role),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String role) {
    final stats = _getStatsForRole(role);
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final stat = stats[i];
          return Container(
            width: 130,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat['icon'] as IconData, color: const Color(0xFFE23744), size: 20),
                const Spacer(),
                Text(stat['value'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1C1C1C))),
                Text(stat['label'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, WidgetRef ref, String role, _RoleConfig config) {
    final items = _getMenuItems(role);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _onMenuTap(context, item['action'] as String),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: config.color, size: 22),
                ),
                const Spacer(),
                Text(item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1C1C1C))),
                Text(item['desc'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ..._getActivityItems(role).map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a['icon'] as IconData, size: 18, color: const Color(0xFFE23744)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(a['sub'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text(a['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _onMenuTap(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening $action...'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFE23744),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  _RoleConfig _getRoleConfig(String role) {
    switch (role) {
      case 'restaurant':
        return _RoleConfig(
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFE23744),
          color2: const Color(0xFFFF6B6B),
          roleLabel: '🍽️  Restaurant Partner',
        );
      case 'rider':
        return _RoleConfig(
          icon: Icons.delivery_dining_rounded,
          color: const Color(0xFF2563EB),
          color2: const Color(0xFF3B82F6),
          roleLabel: '🛵  Delivery Partner',
        );
      case 'admin':
        return _RoleConfig(
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF7C3AED),
          color2: const Color(0xFF8B5CF6),
          roleLabel: '⚙️  Super Admin',
        );
      default:
        return _RoleConfig(
          icon: Icons.person_rounded,
          color: const Color(0xFFE23744),
          color2: const Color(0xFFFF6B6B),
          roleLabel: 'Customer',
        );
    }
  }

  List<Map<String, dynamic>> _getStatsForRole(String role) {
    switch (role) {
      case 'restaurant':
        return [
          {'icon': Icons.receipt_long_rounded, 'value': '--', 'label': "Today's Orders"},
          {'icon': Icons.attach_money_rounded, 'value': '--', 'label': "Revenue"},
          {'icon': Icons.star_rounded, 'value': '--', 'label': "Rating"},
        ];
      case 'rider':
        return [
          {'icon': Icons.delivery_dining_rounded, 'value': '--', 'label': "Deliveries"},
          {'icon': Icons.attach_money_rounded, 'value': '--', 'label': "Earnings"},
          {'icon': Icons.route_rounded, 'value': '--', 'label': "Distance"},
        ];
      case 'admin':
        return [
          {'icon': Icons.storefront_rounded, 'value': '--', 'label': "Restaurants"},
          {'icon': Icons.shopping_bag_rounded, 'value': '--', 'label': "Orders"},
          {'icon': Icons.people_rounded, 'value': '--', 'label': "Users"},
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getMenuItems(String role) {
    switch (role) {
      case 'restaurant':
        return [
          {'icon': Icons.receipt_long_rounded, 'label': 'Orders', 'desc': 'View incoming orders', 'action': 'Orders'},
          {'icon': Icons.menu_book_rounded, 'label': 'Menu', 'desc': 'Manage menu items', 'action': 'Menu'},
          {'icon': Icons.bar_chart_rounded, 'label': 'Analytics', 'desc': 'Sales & performance', 'action': 'Analytics'},
          {'icon': Icons.star_rounded, 'label': 'Reviews', 'desc': 'Customer reviews', 'action': 'Reviews'},
          {'icon': Icons.local_offer_rounded, 'label': 'Promotions', 'desc': 'Offers & discounts', 'action': 'Promotions'},
          {'icon': Icons.settings_rounded, 'label': 'Settings', 'desc': 'Restaurant settings', 'action': 'Settings'},
        ];
      case 'rider':
        return [
          {'icon': Icons.delivery_dining_rounded, 'label': 'Active Deliveries', 'desc': 'Current assignments', 'action': 'Deliveries'},
          {'icon': Icons.attach_money_rounded, 'label': 'Earnings', 'desc': 'Today & history', 'action': 'Earnings'},
          {'icon': Icons.toggle_on_rounded, 'label': 'Go Online', 'desc': 'Toggle availability', 'action': 'Status'},
          {'icon': Icons.map_rounded, 'label': 'Navigation', 'desc': 'Route guidance', 'action': 'Map'},
          {'icon': Icons.history_rounded, 'label': 'History', 'desc': 'Past deliveries', 'action': 'History'},
          {'icon': Icons.person_rounded, 'label': 'Profile', 'desc': 'Your profile', 'action': 'Profile'},
        ];
      case 'admin':
        return [
          {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'desc': 'Platform overview', 'action': 'Dashboard'},
          {'icon': Icons.storefront_rounded, 'label': 'Restaurants', 'desc': 'Manage partners', 'action': 'Restaurants'},
          {'icon': Icons.people_rounded, 'label': 'Users', 'desc': 'Customer management', 'action': 'Users'},
          {'icon': Icons.delivery_dining_rounded, 'label': 'Riders', 'desc': 'Fleet management', 'action': 'Riders'},
          {'icon': Icons.bar_chart_rounded, 'label': 'Analytics', 'desc': 'Platform stats', 'action': 'Analytics'},
          {'icon': Icons.account_balance_rounded, 'label': 'Finance', 'desc': 'Revenue & payouts', 'action': 'Finance'},
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getActivityItems(String role) {
    switch (role) {
      case 'restaurant':
        return [
          {'icon': Icons.receipt_long_rounded, 'title': 'New order received', 'sub': 'Waiting for your confirmation', 'time': 'Just now'},
          {'icon': Icons.star_rounded, 'title': 'New review posted', 'sub': '4.5 stars — "Great food!"', 'time': '2m ago'},
          {'icon': Icons.check_circle_rounded, 'title': 'Order #1234 delivered', 'sub': 'Customer confirmed delivery', 'time': '15m ago'},
        ];
      case 'rider':
        return [
          {'icon': Icons.delivery_dining_rounded, 'title': 'New delivery assigned', 'sub': 'Restaurant → Customer', 'time': 'Just now'},
          {'icon': Icons.attach_money_rounded, 'title': 'Earning credited', 'sub': '₹45 for last delivery', 'time': '20m ago'},
          {'icon': Icons.star_rounded, 'title': 'Rating received', 'sub': '5 stars from customer', 'time': '1h ago'},
        ];
      case 'admin':
        return [
          {'icon': Icons.storefront_rounded, 'title': 'New restaurant registered', 'sub': 'Pending verification', 'time': '5m ago'},
          {'icon': Icons.people_rounded, 'title': '120 new users today', 'sub': 'Up 23% from yesterday', 'time': '1h ago'},
          {'icon': Icons.warning_rounded, 'title': 'Support ticket opened', 'sub': 'Order dispute — #5678', 'time': '2h ago'},
        ];
      default:
        return [];
    }
  }
}

class _RoleConfig {
  final IconData icon;
  final Color color;
  final Color color2;
  final String roleLabel;

  const _RoleConfig({
    required this.icon,
    required this.color,
    required this.color2,
    required this.roleLabel,
  });
}
