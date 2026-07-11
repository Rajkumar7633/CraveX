import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zomato_clone/core/theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _selectedPeriodIndex = 0;
  int _selectedMetricIndex = 0;

  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];
  final List<String> _metrics = ['Orders', 'Revenue', 'Users', 'Restaurants'];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Analytics & Reports',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _periods.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedPeriodIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPeriodIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.dividerColor,
                              ),
                            ),
                            child: Text(
                              _periods[index],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Metrics
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Orders',
                    value: '12,456',
                    change: '+15.2%',
                    isPositive: true,
                    icon: Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Total Revenue',
                    value: '₹45.2L',
                    change: '+18.5%',
                    isPositive: true,
                    icon: Attach.money_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Active Users',
                    value: '8,234',
                    change: '+12.1%',
                    isPositive: true,
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Avg. Order Value',
                    value: '₹362',
                    change: '-2.3%',
                    isPositive: false,
                    icon: Icons.shopping_cart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _MainChartCard(
                    title: 'Revenue Trend',
                    height: 350,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PieChartCard(
                    title: 'Order Distribution',
                    height: 350,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detailed Metrics
            _DetailedMetricsSection(
              selectedMetricIndex: _selectedMetricIndex,
              metrics: _metrics,
              onMetricChanged: (index) => setState(() => _selectedMetricIndex = index),
            ),
            const SizedBox(height: 24),

            // Top Performing
            Row(
              children: [
                Expanded(
                  child: _TopPerformersCard(
                    title: 'Top Restaurants',
                    type: 'restaurant',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TopPerformersCard(
                    title: 'Top Riders',
                    type: 'rider',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Zone Analysis
            _ZoneAnalysisCard(),
            const SizedBox(height: 24),

            // Download Reports
            _ReportsSection(),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isPositive
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MainChartCard extends StatelessWidget {
  final String title;
  final double height;

  const _MainChartCard({
    required this.title,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Revenue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppTheme.textTertiary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Line Chart Placeholder',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final String title;
  final double height;

  const _PieChartCard({
    required this.title,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart,
                      size: 48,
                      color: AppTheme.textTertiary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pie Chart Placeholder',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedMetricsSection extends StatelessWidget {
  final int selectedMetricIndex;
  final List<String> metrics;
  final Function(int) onMetricChanged;

  const _DetailedMetricsSection({
    required this.selectedMetricIndex,
    required this.metrics,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedMetricIndex;
                return GestureDetector(
                  onTap: () => onMetricChanged(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      metrics[index],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Detailed Chart Placeholder',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
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

class _TopPerformersCard extends StatelessWidget {
  final String title;
  final String type;

  const _TopPerformersCard({
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (type == 'restaurant') ...[
            _TopPerformerItem(
              name: 'Paradise Biryani',
              value: '₹5.2L',
              rank: 1,
            ),
            const SizedBox(height: 12),
            _TopPerformerItem(
              name: 'Truffles',
              value: '₹4.8L',
              rank: 2,
            ),
            const SizedBox(height: 12),
            _TopPerformerItem(
              name: 'Meghana Foods',
              value: '₹4.5L',
              rank: 3,
            ),
          ] else ...[
            _TopPerformerItem(
              name: 'Rajesh Kumar',
              value: '₹78,900',
              rank: 1,
            ),
            const SizedBox(height: 12),
            _TopPerformerItem(
              name: 'Suresh Yadav',
              value: '₹65,450',
              rank: 2,
            ),
            const SizedBox(height: 12),
            _TopPerformerItem(
              name: 'Priya Sharma',
              value: '₹58,340',
              rank: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _TopPerformerItem extends StatelessWidget {
  final String name;
  final String value;
  final int rank;

  const _TopPerformerItem({
    required this.name,
    required this.value,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppTheme.accentColor
                : rank == 2
                    ? AppTheme.textSecondary
                    : AppTheme.warningColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ZoneAnalysisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _ZoneRow(
            zone: 'Koramangala',
            orders: '2,345',
            revenue: '₹8.5L',
            riders: '45',
            demand: 'High',
            demandColor: AppTheme.errorColor,
          ),
          const SizedBox(height: 12),
          _ZoneRow(
            zone: 'Indiranagar',
            orders: '1,876',
            revenue: '₹6.8L',
            riders: '38',
            demand: 'Medium',
            demandColor: AppTheme.warningColor,
          ),
          const SizedBox(height: 12),
          _ZoneRow(
            zone: 'Electronic City',
            orders: '1,234',
            revenue: '₹4.5L',
            riders: '28',
            demand: 'Low',
            demandColor: AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          _ZoneRow(
            zone: 'Whitefield',
            orders: '987',
            revenue: '₹3.2L',
            riders: '22',
            demand: 'Medium',
            demandColor: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String zone;
  final String orders;
  final String revenue;
  final String riders;
  final String demand;
  final Color demandColor;

  const _ZoneRow({
    required this.zone,
    required this.orders,
    required this.revenue,
    required this.riders,
    required this.demand,
    required this.demandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              zone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              orders,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              revenue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              riders,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: demandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              demand,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: demandColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReportButton(
                  icon: Icons.description,
                  label: 'Daily Report',
                  format: 'PDF',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportButton(
                  icon: Icons.table_chart,
                  label: 'Weekly Report',
                  format: 'Excel',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportButton(
                  icon: Icons.assessment,
                  label: 'Monthly Report',
                  format: 'PDF',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportButton(
                  icon: Icons.analytics,
                  label: 'Custom Report',
                  format: 'CSV',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String format;

  const _ReportButton({
    required this.icon,
    required this.label,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            format,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
