import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RidersScreen extends ConsumerStatefulWidget {
  const RidersScreen({super.key});

  @override
  ConsumerState<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends ConsumerState<RidersScreen> with SingleTickerProviderStateMixin {
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
          'Rider Management',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending Verification'),
            Tab(text: 'Active Riders'),
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
    final pending = MockData.pendingRiders;
    
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pending verifications',
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
        return _RiderApprovalCard(
          rider: r,
          onApprove: () => _approve(r),
          onReject: () => _showRejectDialog(r),
        );
      },
    );
  }

  Widget _activeList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active riders list
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF2ECC71)),
            ),
            title: Text(MockData.demoRider.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text('${MockData.demoRider.rating}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text('${MockData.demoRider.totalDeliveries} deliveries', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(MockData.demoRider.vehicleType, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: MockData.demoRider.isOnline,
              onChanged: (_) {},
              activeColor: const Color(0xFF2ECC71),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Performance Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 16),
        ...MockData.riderPerformance.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: p['onTime'] as double,
                  color: AppTheme.primaryRed,
                  backgroundColor: const Color(0xFFE0E0E0),
                ),
                const SizedBox(height: 4),
                Text('${((p['onTime'] as double) * 100).toInt()}% on-time', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _approve(Rider rider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rider.name} approved'),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectDialog(Rider rider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject ${rider.name}'),
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
                  content: Text('${rider.name} rejected'),
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
}

class _RiderApprovalCard extends StatelessWidget {
  final Rider rider;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RiderApprovalCard({
    required this.rider,
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_rounded, color: AppTheme.primaryRed),
        ),
        title: Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text('${rider.phone} • ${rider.vehicleType}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Documents',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _docChip('Driving License', true),
              const SizedBox(width: 8),
              _docChip('Vehicle RC', true),
              const SizedBox(width: 8),
              _docChip('Aadhaar', false),
            ],
          ),
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
    );
  }

  Widget _docChip(String label, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFE8F4E8) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: verified ? const Color(0xFF2ECC71) : const Color(0xFFFFB800),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: verified ? const Color(0xFF2ECC71) : const Color(0xFFFFB800),
            ),
          ),
        ],
      ),
    );
  }
}
