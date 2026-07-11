import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zomato_clone/core/theme/app_theme.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Earnings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Total Earnings Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFFC41E32)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹12,450',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+15% from last week',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: (index) => setState(() => _selectedTabIndex = index),
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _TodayTab(),
                _WeeklyTab(),
                _MonthlyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EarningsSummaryCard(
          label: 'Base Earnings',
          value: '₹850',
          icon: Attach.money_outlined,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _EarningsSummaryCard(
          label: 'Tips',
          value: '₹120',
          icon: Icons.volunteer_activism,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: 12),
        _EarningsSummaryCard(
          label: 'Incentives',
          value: '₹280',
          icon: Icons.card_giftcard,
          color: AppTheme.accentColor,
        ),
        const SizedBox(height: 24),

        Text(
          'Today\'s Deliveries',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _DeliveryRecord(
          orderId: '#ORD12345',
          earnings: '₹45',
          distance: '3.2 km',
          time: '10:30 AM',
        ),
        const SizedBox(height: 12),
        _DeliveryRecord(
          orderId: '#ORD12346',
          earnings: '₹52',
          distance: '4.1 km',
          time: '11:45 AM',
        ),
        const SizedBox(height: 12),
        _DeliveryRecord(
          orderId: '#ORD12347',
          earnings: '₹38',
          distance: '2.8 km',
          time: '1:15 PM',
        ),
        const SizedBox(height: 12),
        _DeliveryRecord(
          orderId: '#ORD12348',
          earnings: '₹65',
          distance: '5.5 km',
          time: '2:30 PM',
        ),
      ],
    );
  }
}

class _WeeklyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly Chart Placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
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
                  'Weekly Earnings Chart',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _WeeklySummaryRow(
          day: 'Monday',
          earnings: '₹1,200',
          deliveries: '8',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Tuesday',
          earnings: '₹1,450',
          deliveries: '10',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Wednesday',
          earnings: '₹1,380',
          deliveries: '9',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Thursday',
          earnings: '₹1,520',
          deliveries: '11',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Friday',
          earnings: '₹1,650',
          deliveries: '12',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Saturday',
          earnings: '₹2,100',
          deliveries: '15',
        ),
        const SizedBox(height: 12),
        _WeeklySummaryRow(
          day: 'Sunday',
          earnings: '₹3,150',
          deliveries: '18',
        ),
      ],
    );
  }
}

class _MonthlyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EarningsSummaryCard(
          label: 'This Month',
          value: '₹45,680',
          icon: Attach.money_outlined,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _EarningsSummaryCard(
          label: 'Last Month',
          value: '₹42,350',
          icon: Icons.history,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(height: 24),

        Text(
          'Payout History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _PayoutRecord(
          date: 'Jan 15, 2026',
          amount: '₹22,340',
          status: 'Paid',
        ),
        const SizedBox(height: 12),
        _PayoutRecord(
          date: 'Jan 1, 2026',
          amount: '₹23,340',
          status: 'Paid',
        ),
        const SizedBox(height: 12),
        _PayoutRecord(
          date: 'Dec 15, 2025',
          amount: '₹21,890',
          status: 'Paid',
        ),
      ],
    );
  }
}

class _EarningsSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _EarningsSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRecord extends StatelessWidget {
  final String orderId;
  final String earnings;
  final String distance;
  final String time;

  const _DeliveryRecord({
    required this.orderId,
    required this.earnings,
    required this.distance,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.directions_bike,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            earnings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryRow extends StatelessWidget {
  final String day;
  final String earnings;
  final String deliveries;

  const _WeeklySummaryRow({
    required this.day,
    required this.earnings,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            earnings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
          Text(
            '$deliveries deliveries',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _PayoutRecord extends StatelessWidget {
  final String date;
  final String amount;
  final String status;

  const _PayoutRecord({
    required this.date,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
