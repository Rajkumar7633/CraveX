import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              Expanded(child: StatCard(title: 'Weekly Sales', value: '₹85K', icon: Icons.trending_up)),
              SizedBox(width: 12),
              Expanded(child: StatCard(title: 'Orders', value: '342', icon: Icons.receipt)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.5), FlSpot(5, 6), FlSpot(6, 5.5)],
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
          const SizedBox(height: 24),
          const Text('Best Selling Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _itemRow('Chicken Biryani', 145, 0.45),
          _itemRow('Paneer Butter Masala', 98, 0.30),
          _itemRow('Gulab Jamun', 67, 0.20),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Download Report (PDF)')),
        ],
      ),
    );
  }

  Widget _itemRow(String name, int count, double pct) {
    return ListTile(
      title: Text(name),
      subtitle: LinearProgressIndicator(value: pct, color: AppTheme.primaryRed),
      trailing: Text('$count orders'),
    );
  }
}
