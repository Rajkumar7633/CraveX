import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = MockData.adminStats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Chip(
            avatar: const CircleAvatar(backgroundColor: Colors.green, radius: 6),
            label: Text('${stats['todayOrders']} orders today'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              StatCard(title: 'Total Orders', value: '${stats['totalOrders']}', icon: Icons.receipt),
              StatCard(title: 'GMV (₹ Cr)', value: '${stats['gmv']}', icon: Icons.trending_up),
              StatCard(title: 'Restaurants', value: '${stats['activeRestaurants']}', icon: Icons.store),
              StatCard(title: 'Riders', value: '${stats['activeRiders']}', icon: Icons.delivery_dining),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Volume (7 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.toInt() % 7], style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [FlSpot(0, 280), FlSpot(1, 310), FlSpot(2, 290), FlSpot(3, 342), FlSpot(4, 380), FlSpot(5, 420), FlSpot(6, 395)],
                                  isCurved: true,
                                  color: AppTheme.primaryRed,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: AppTheme.primaryRed.withValues(alpha: 0.1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _alertCard('Pending Approvals', '${stats['pendingApprovals']}', Icons.pending_actions, Colors.orange, () => context.go('/restaurants')),
                    const SizedBox(height: 12),
                    _alertCard('Open Tickets', '${stats['openTickets']}', Icons.support_agent, Colors.blue, () => context.go('/support')),
                    const SizedBox(height: 12),
                    _alertCard('Live Orders', '${stats['todayOrders']}', Icons.local_shipping, AppTheme.primaryRed, () => context.go('/orders')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...MockData.adminActivityLog.map((a) => ListTile(
                leading: Icon(_activityIcon(a['icon'] as String), color: AppTheme.primaryRed),
                title: Text(a['title'] as String),
                subtitle: Text(a['time'] as String),
                trailing: Chip(label: Text(a['type'] as String, style: const TextStyle(fontSize: 10))),
              )),
        ],
      ),
    );
  }

  IconData _activityIcon(String name) => switch (name) {
        'store' => Icons.store,
        'delivery' => Icons.delivery_dining,
        'receipt' => Icons.receipt,
        'support' => Icons.support_agent,
        _ => Icons.info,
      };

  Widget _alertCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
