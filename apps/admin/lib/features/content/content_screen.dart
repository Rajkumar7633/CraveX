import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Content & Promotions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Banners'), Tab(text: 'Coupons'), Tab(text: 'Push Campaigns')],
        ),
        actions: [
          ElevatedButton.icon(onPressed: () => _showCreateDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Create')),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: MockData.adminBanners.length,
            itemBuilder: (_, i) {
              final b = MockData.adminBanners[i];
              return Card(
                child: SwitchListTile(
                  title: Text(b.title),
                  subtitle: Text(b.subtitle),
                  value: b.isActive,
                  onChanged: (_) {},
                ),
              );
            },
          ),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: MockData.adminCoupons.length,
            itemBuilder: (_, i) {
              final c = MockData.adminCoupons[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_offer, color: AppTheme.primaryRed),
                  title: Text(c.code),
                  subtitle: Text('${c.type} • ${c.scope} • Max ₹${c.maxDiscount.toInt()}'),
                  trailing: Switch(value: c.isActive, onChanged: (_) {}),
                ),
              );
            },
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: MockData.pushCampaigns.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text(p['title'] as String),
                    subtitle: Text('${p['segment']} • ${p['sent']} sent • ${p['opened']} opened'),
                    trailing: Chip(label: Text(p['status'] as String)),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Title')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }
}
