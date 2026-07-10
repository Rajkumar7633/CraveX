import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> with SingleTickerProviderStateMixin {
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
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pending Approvals'), Tab(text: 'Active Restaurants')],
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.pendingRestaurants.length,
      itemBuilder: (_, i) {
        final r = MockData.pendingRestaurants[i];
        return Card(
          child: ListTile(
            title: Text(r.name),
            subtitle: Text('${r.ownerName} • ${r.city} • ${r.status}'),
            trailing: r.status == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () => _showRejectDialog(r.name), child: const Text('Reject')),
                      ElevatedButton(onPressed: () => _approve(r.name), child: const Text('Approve')),
                    ],
                  )
                : Chip(label: Text(r.status)),
          ),
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
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1), child: Text(r.name[0])),
            title: Text(r.name),
            subtitle: Text('${r.cuisines.join(', ')} • ⭐ ${r.rating} • ${r.address}'),
            trailing: PopupMenuButton(
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

  void _approve(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name approved')));
  }

  void _showRejectDialog(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject $name'),
        content: const TextField(decoration: InputDecoration(labelText: 'Reason for rejection')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _approve('$name rejected'); }, child: const Text('Reject')),
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
          ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name suspended'))); }, child: const Text('Suspend')),
        ],
      ),
    );
  }
}
