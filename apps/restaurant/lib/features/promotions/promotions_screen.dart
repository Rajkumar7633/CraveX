import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _promos = [
    {'title': '50% OFF on Biryani', 'type': 'percent', 'value': '50%', 'status': 'active', 'start': 'Jul 1', 'end': 'Jul 31'},
    {'title': 'Flat ₹100 OFF', 'type': 'flat', 'value': '₹100', 'status': 'scheduled', 'start': 'Jul 15', 'end': 'Jul 20'},
    {'title': 'Free Delivery Weekend', 'type': 'delivery', 'value': 'Free', 'status': 'expired', 'start': 'Jun 1', 'end': 'Jun 30'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreatePromo()),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _promos.length,
        itemBuilder: (_, i) {
          final p = _promos[i];
          final status = p['status'] as String;
          final color = status == 'active' ? Colors.green : status == 'scheduled' ? Colors.orange : Colors.grey;
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1), child: const Icon(Icons.local_offer, color: AppTheme.primaryRed)),
              title: Text(p['title'] as String),
              subtitle: Text('${p['start']} — ${p['end']} • ${p['type']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(p['value'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Chip(label: Text(status, style: TextStyle(fontSize: 10, color: color)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePromo,
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add),
        label: const Text('Create Promo'),
      ),
    );
  }

  void _showCreatePromo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create Promotion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Promotion Title')),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'percent', child: Text('Percentage Off')),
                DropdownMenuItem(value: 'flat', child: Text('Flat Amount Off')),
                DropdownMenuItem(value: 'delivery', child: Text('Free Delivery')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion created'))); }, child: const Text('Create')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
