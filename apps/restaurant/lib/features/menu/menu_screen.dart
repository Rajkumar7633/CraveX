import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:widgets/widgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _items = MockData.menuItems('rest-1');
  final _availability = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _items.length,
        onReorder: (old, newIdx) {
          setState(() {
            if (newIdx > old) newIdx--;
            final item = _items.removeAt(old);
            _items.insert(newIdx, item);
          });
        },
        itemBuilder: (_, i) {
          final item = _items[i];
          final available = _availability[item.id] ?? item.isAvailable;
          return Card(
            key: ValueKey(item.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: VegIndicator(isVeg: item.isVeg),
              title: Text(item.name),
              subtitle: Text('₹${item.price.toInt()} • ${item.description}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: available,
                    onChanged: (v) => setState(() => _availability[item.id] = v),
                  ),
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Item Name')),
            TextField(decoration: InputDecoration(labelText: 'Description')),
            TextField(decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(decoration: InputDecoration(labelText: 'Category')),
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
