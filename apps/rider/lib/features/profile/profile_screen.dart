import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rider = MockData.demoRider;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
                const SizedBox(height: 12),
                Text(rider.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('⭐ ${rider.rating} • ${rider.totalDeliveries} deliveries'),
                const SizedBox(height: 8),
                Chip(label: Text(rider.isVerified ? 'Verified' : 'Pending Verification'), backgroundColor: rider.isVerified ? Colors.green[100] : Colors.orange[100]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoTile(Icons.phone, 'Phone', rider.phone),
          _infoTile(Icons.two_wheeler, 'Vehicle', rider.vehicleType.toUpperCase()),
          _infoTile(Icons.account_balance, 'Bank Account', '****4567 (HDFC)'),
          const Divider(height: 32),
          const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _docTile('Driving License', true, 'Valid until Dec 2027'),
          _docTile('Vehicle RC', true, 'Valid until Mar 2028'),
          _docTile('Aadhaar', true, 'Verified'),
          _docTile('PAN', false, 'Renewal required'),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(leading: Icon(icon, color: AppTheme.primaryRed), title: Text(label), subtitle: Text(value));
  }

  Widget _docTile(String name, bool valid, String detail) {
    return ListTile(
      leading: Icon(valid ? Icons.check_circle : Icons.warning, color: valid ? Colors.green : Colors.orange),
      title: Text(name),
      subtitle: Text(detail),
    );
  }
}
