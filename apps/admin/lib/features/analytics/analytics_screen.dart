import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
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
              StatCard(title: 'New Customers', value: '${MockData.analyticsMetrics['newCustomers']}', icon: Icons.person_add),
              StatCard(title: 'Retention Rate', value: '${MockData.analyticsMetrics['retention']}%', icon: Icons.repeat),
              StatCard(title: 'Avg Order Value', value: '₹${MockData.analyticsMetrics['aov']}', icon: Icons.shopping_bag),
              StatCard(title: 'Cancel Rate', value: '${MockData.analyticsMetrics['cancelRate']}%', icon: Icons.cancel),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GMV Trend (Monthly)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][v.toInt() % 6], style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: List.generate(6, (i) => BarChartGroupData(
                                    x: i,
                                    barRods: [BarChartRodData(toY: [32.0, 38.0, 35.0, 42.0, 45.0, 48.0][i], color: AppTheme.primaryRed, width: 20, borderRadius: BorderRadius.circular(4))],
                                  )),
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('City-wise Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...MockData.cityOrderVolume.entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(width: 80, child: Text(e.key)),
                                  Expanded(child: LinearProgressIndicator(value: e.value / 100, color: AppTheme.primaryRed)),
                                  const SizedBox(width: 8),
                                  Text('${e.value}%'),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Demand Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('Peak demand: Koramangala, HSR, Indiranagar (6-9 PM)', style: TextStyle(color: Colors.grey[600]))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
