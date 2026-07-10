import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          SizedBox(
            width: 240,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppTheme.primaryRed, child: Text(MockData.demoUser.name[0], style: const TextStyle(color: Colors.white))),
              title: Text(MockData.demoUser.name),
              subtitle: Text('${MockData.demoUser.phone} • ${MockData.demoUser.email}'),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'orders', child: Text('View Orders')),
                  const PopupMenuItem(value: 'block', child: Text('Block User')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...MockData.customerComplaints.map((c) => Card(
                child: ListTile(
                  leading: Icon(c['resolved'] as bool ? Icons.check_circle : Icons.warning, color: c['resolved'] as bool ? Colors.green : Colors.orange),
                  title: Text(c['subject'] as String),
                  subtitle: Text('${c['customer']} • ${c['date']}'),
                  trailing: c['resolved'] as bool ? const Chip(label: Text('Resolved')) : TextButton(onPressed: () {}, child: const Text('Resolve')),
                ),
              )),
        ],
      ),
    );
  }
}
