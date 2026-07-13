import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  bool _isOnline = false;
  DeliveryRequest? _pendingRequest;
  Timer? _countdown;
  int _secondsLeft = 15;

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _toggleOnline(bool v) {
    setState(() => _isOnline = v);
    if (v) _simulateRequest();
  }

  void _simulateRequest() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isOnline || !mounted) return;
      setState(() {
        _pendingRequest = DeliveryRequest(
          orderId: 'ORD-12345',
          restaurantName: 'Meghana Foods',
          restaurantAddress: 'Koramangala, Bangalore',
          customerAddress: MockData.addresses.first.fullAddress,
          earnings: 45,
          distanceKm: 3.2,
        );
        _secondsLeft = 15;
      });
      _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _countdown?.cancel();
          setState(() => _pendingRequest = null);
        } else {
          setState(() => _secondsLeft--);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final rider = MockData.demoRider;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Hi, ${rider.name.split(' ').first}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: const Color(0xFFE23744)),
            onPressed: () => context.push('/support'),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Colors.black),
            onPressed: () => context.push('/support'),
          ),
        ],
      ),
      drawer: _drawer(context, rider),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Online/Offline toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isOnline ? const Color(0xFF2ECC71) : const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF2ECC71) : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isOnline ? Icons.online_prediction_rounded : Icons.offline_bolt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            _isOnline ? 'Receiving delivery requests' : 'Go online to receive orders',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      onChanged: _toggleOnline,
                      activeColor: const Color(0xFF2ECC71),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: const [
                  StatCard(title: "Today's Earnings", value: '₹850', icon: Icons.currency_rupee_rounded, color: Color(0xFF2ECC71)),
                  StatCard(title: 'Deliveries', value: '12', icon: Icons.delivery_dining_rounded, color: Color(0xFFE23744)),
                  StatCard(title: 'Rating', value: '4.8', icon: Icons.star_rounded, color: Color(0xFFFFB800)),
                  StatCard(title: 'Hours Online', value: '6.5h', icon: Icons.access_time_rounded, color: Color(0xFF3498DB)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Active delivery section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Delivery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View History', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.local_shipping_rounded, size: 48, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 12),
                    const Text(
                      'No active delivery',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accept an order to start delivering',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_pendingRequest != null) _requestOverlay(),
        ],
      ),
    );
  }

  Widget _requestOverlay() {
    final r = _pendingRequest!;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Delivery Request',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_secondsLeft sec',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryRed),
                  ),
                ),
                const Divider(height: 32),
                _requestTile(Icons.store_rounded, r.restaurantName, r.restaurantAddress),
                _requestTile(Icons.home_rounded, 'Customer', r.customerAddress),
                _requestTile(Icons.currency_rupee_rounded, 'Earn ₹${r.earnings.toInt()}', '${r.distanceKm} km'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _pendingRequest = null),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE23744)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Accept',
                        onPressed: () {
                          _countdown?.cancel();
                          setState(() => _pendingRequest = null);
                          context.push('/delivery/${r.orderId}');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _requestTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryRed),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    );
  }

  Drawer _drawer(BuildContext context, Rider rider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(rider.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('${rider.rating} • ${rider.totalDeliveries} deliveries', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.currency_rupee_rounded, 'Earnings', () { Navigator.pop(context); context.push('/earnings'); }),
          _drawerItem(Icons.person_rounded, 'Profile', () { Navigator.pop(context); context.push('/profile'); }),
          _drawerItem(Icons.description_rounded, 'Documents', () { Navigator.pop(context); context.push('/profile'); }),
          _drawerItem(Icons.support_agent_rounded, 'Support & SOS', () { Navigator.pop(context); context.push('/support'); }),
          const Divider(height: 1),
          _drawerItem(Icons.logout_rounded, 'Logout', () => context.push('/login'), isDestructive: true),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? const Color(0xFFE23744) : const Color(0xFF1C1C1C)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? const Color(0xFFE23744) : const Color(0xFF1C1C1C))),
      onTap: onTap,
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = const Color(0xFFE23744),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
