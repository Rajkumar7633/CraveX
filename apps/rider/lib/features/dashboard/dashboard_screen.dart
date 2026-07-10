import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
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
      appBar: AppBar(
        title: Text('Hi, ${rider.name.split(' ').first}'),
        actions: [
          IconButton(icon: const Icon(Icons.sos, color: Colors.red), onPressed: () => context.go('/support')),
          IconButton(icon: const Icon(Icons.support_agent), onPressed: () => context.go('/support')),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(rider.name),
              accountEmail: Text('⭐ ${rider.rating} • ${rider.totalDeliveries} deliveries'),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.currency_rupee), title: const Text('Earnings'), onTap: () { Navigator.pop(context); context.go('/earnings'); }),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () { Navigator.pop(context); context.go('/profile'); }),
            ListTile(leading: const Icon(Icons.description), title: const Text('Documents'), onTap: () { Navigator.pop(context); context.go('/profile'); }),
            ListTile(leading: const Icon(Icons.support_agent), title: const Text('Support & SOS'), onTap: () { Navigator.pop(context); context.go('/support'); }),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => context.go('/login')),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: _isOnline ? Colors.green[50] : Colors.grey[100],
                child: SwitchListTile(
                  title: Text(_isOnline ? 'You are ONLINE' : 'You are OFFLINE', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isOnline ? 'Receiving delivery requests' : 'Go online to receive orders'),
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeThumbColor: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: StatCard(title: "Today's Earnings", value: '₹850', icon: Icons.currency_rupee)),
                  SizedBox(width: 12),
                  Expanded(child: StatCard(title: 'Deliveries', value: '12', icon: Icons.delivery_dining)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Active Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: AppTheme.primaryRed),
                  title: const Text('No active delivery'),
                  subtitle: const Text('Accept an order to start'),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('New Delivery Request', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('$_secondsLeft sec', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                const Divider(height: 32),
                ListTile(leading: const Icon(Icons.restaurant), title: Text(r.restaurantName), subtitle: Text(r.restaurantAddress)),
                ListTile(leading: const Icon(Icons.home), title: const Text('Customer'), subtitle: Text(r.customerAddress)),
                ListTile(leading: const Icon(Icons.currency_rupee), title: Text('Earn ₹${r.earnings.toInt()}'), subtitle: Text('${r.distanceKm} km')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _pendingRequest = null), child: const Text('Reject'))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        _countdown?.cancel();
                        setState(() => _pendingRequest = null);
                        context.go('/delivery/${r.orderId}');
                      },
                      child: const Text('Accept'),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
