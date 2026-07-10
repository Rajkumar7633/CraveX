import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Finance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Restaurant Payouts'), Tab(text: 'Rider Payouts'), Tab(text: 'Revenue Reports')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _payoutList('restaurant'),
          _payoutList('rider'),
          _revenueReport(),
        ],
      ),
    );
  }

  Widget _payoutList(String type) {
    final payouts = MockData.payouts.where((p) => p.entityType == type).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            StatCard(title: 'Pending', value: '₹${MockData.financeSummary['pendingPayouts']}', icon: Icons.pending),
            StatCard(title: 'Processed (Month)', value: '₹${MockData.financeSummary['processedMonth']}', icon: Icons.check_circle),
            StatCard(title: 'Commission', value: '₹${MockData.financeSummary['commission']}', icon: Icons.percent),
          ],
        ),
        const SizedBox(height: 16),
        ...payouts.map((p) => Card(
              child: ListTile(
                title: Text(p.entityName),
                subtitle: Text('${p.date.day}/${p.date.month}/${p.date.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${p.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    if (p.status == 'pending')
                      ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payout processed for ${p.entityName}'))), child: const Text('Process'))
                    else
                      Chip(label: Text(p.status)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _revenueReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ...MockData.revenueBreakdown.entries.map((e) => Card(
              child: ListTile(
                title: Text(e.key),
                trailing: Text('₹${e.value} L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryRed)),
              ),
            )),
        const SizedBox(height: 24),
        const Text('GST Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download GST Report — Q2 2026'),
          trailing: ElevatedButton(onPressed: () {}, child: const Text('PDF')),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Chargeback Report'),
          trailing: ElevatedButton(onPressed: () {}, child: const Text('Excel')),
        ),
      ],
    );
  }
}
