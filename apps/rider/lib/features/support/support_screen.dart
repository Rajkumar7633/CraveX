import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class RiderSupportScreen extends StatefulWidget {
  const RiderSupportScreen({super.key});

  @override
  State<RiderSupportScreen> createState() => _RiderSupportScreenState();
}

class _RiderSupportScreenState extends State<RiderSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: const Icon(Icons.sos, color: Colors.red, size: 32),
              title: const Text('SOS Emergency', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('Alert emergency contacts & support'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _showSosDialog(),
                child: const Text('SOS'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Get Help', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ListTile(leading: const Icon(Icons.chat), title: const Text('Live Chat Support'), subtitle: const Text('Available 24/7'), onTap: () {}),
          ListTile(leading: const Icon(Icons.phone), title: const Text('Call Support'), subtitle: const Text('1800-XXX-XXXX'), onTap: () {}),
          const Divider(),
          const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...['Customer unavailable', 'Wrong address', 'Restaurant delay', 'Payment issue (COD)', 'Safety concern'].map((issue) => ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(issue),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted: $issue'))),
              )),
          const Divider(),
          const Text('Training', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ListTile(
            leading: const Icon(Icons.school, color: AppTheme.primaryRed),
            title: const Text('Delivery Guidelines Quiz'),
            subtitle: const Text('Score: 85% — Completed'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.sos, color: Colors.red, size: 48),
        title: const Text('Emergency SOS'),
        content: const Text('This will alert emergency contacts, nearby support, and share your live location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS alert sent — Support team notified'), backgroundColor: Colors.red));
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }
}
