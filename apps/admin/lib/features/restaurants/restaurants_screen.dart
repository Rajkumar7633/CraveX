import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Restaurant Management',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Active Restaurants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _pendingList(),
          _activeList(),
        ],
      ),
    );
  }

  Widget _pendingList() {
    final pending = MockData.pendingRestaurants;
    
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (_, i) {
        final r = pending[i];
        return _RestaurantApprovalCard(
          restaurant: r,
          onApprove: () => _approve(r),
          onReject: () => _showRejectDialog(r),
        );
      },
    );
  }

  Widget _activeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.restaurants.length,
      itemBuilder: (_, i) {
        final r = MockData.restaurants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  r.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryRed),
                ),
              ),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(r.cuisines.join(', '), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text('${r.rating}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(r.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Commission')),
                const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
              ],
              onSelected: (v) {
                if (v == 'suspend') _showSuspendDialog(r.name);
              },
            ),
          ),
        );
      },
    );
  }

  void _approve(Restaurant restaurant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restaurant.name} approved'),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectDialog(Restaurant restaurant) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject ${restaurant.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: reasonController,
              hintText: 'Reason for rejection',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${restaurant.name} rejected'),
                  backgroundColor: const Color(0xFFE23744),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Suspend $name?'),
        content: const Text('This will hide the restaurant from customers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name suspended'),
                  backgroundColor: const Color(0xFFE23744),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}

class _RestaurantApprovalCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RestaurantApprovalCard({
    required this.restaurant,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      restaurant.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${restaurant.ownerName} • ${restaurant.city}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(color: AppTheme.primaryRed, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
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
                    text: 'Approve',
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
