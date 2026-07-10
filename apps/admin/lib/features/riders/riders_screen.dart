import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Rider Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pending Verification'), Tab(text: 'Active Riders')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: MockData.pendingRiders.length,
            itemBuilder: (_, i) {
              final r = MockData.pendingRiders[i];
              return Card(
                child: ExpansionTile(
                  title: Text(r.name),
                  subtitle: Text('${r.phone} • ${r.vehicleType}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _docChip('License', true),
                          _docChip('RC', true),
                          _docChip('Aadhaar', false),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () {}, child: const Text('Reject')),
                        ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.name} approved'))), child: const Text('Approve')),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(MockData.demoRider.name),
                  subtitle: Text('⭐ ${MockData.demoRider.rating} • ${MockData.demoRider.totalDeliveries} deliveries • ${MockData.demoRider.vehicleType}'),
                  trailing: Switch(value: MockData.demoRider.isOnline, onChanged: (_) {}),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Performance Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
              ...MockData.riderPerformance.map((p) => ListTile(
                    title: Text(p['name'] as String),
                    subtitle: LinearProgressIndicator(value: p['onTime'] as double, color: AppTheme.primaryRed),
                    trailing: Text('${((p['onTime'] as double) * 100).toInt()}% on-time'),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docChip(String label, bool verified) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(verified ? Icons.check_circle : Icons.warning, size: 16, color: verified ? Colors.green : Colors.orange),
        label: Text(label),
      ),
    );
  }
}
