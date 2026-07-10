import 'package:core/core.dart';
import 'package:flutter/material.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _addresses = List<Address>.from(MockData.addresses);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (_, i) {
          final a = _addresses[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(
                a.label == 'Home' ? Icons.home : a.label == 'Work' ? Icons.work : Icons.location_on,
              ),
              title: Text(a.label),
              subtitle: Text(a.fullAddress),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) {
                  if (v == 'delete') setState(() => _addresses.removeAt(i));
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              items: ['Home', 'Work', 'Other']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const TextField(decoration: InputDecoration(labelText: 'Address')),
            const TextField(decoration: InputDecoration(labelText: 'Landmark')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}
