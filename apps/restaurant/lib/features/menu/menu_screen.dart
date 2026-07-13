import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _items = MockData.menuItems('rest-1');
  final _availability = <String, bool>{};
  String _selectedCategory = 'All';

  final _categories = ['All', 'Starters', 'Main Course', 'Biryani', 'Desserts', 'Beverages'];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'All'
        ? _items
        : _items.where((item) => item.category == _selectedCategory).toList();

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
          'Menu Management',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: AppTheme.primaryRed),
            onPressed: _showUploadDialog,
            tooltip: 'Upload CSV',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryRed),
            onPressed: _showAddDialog,
            tooltip: 'Add Item',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final category = _categories[i];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedCategory = category),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryRed,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1C1C1C),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppTheme.primaryRed : const Color(0xFFE0E0E0)),
                    ),
                  ),
                );
              },
            ),
          ),
          // Menu items list
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No items in $_selectedCategory',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Add First Item',
                          onPressed: _showAddDialog,
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    onReorder: (old, newIdx) {
                      setState(() {
                        if (newIdx > old) newIdx--;
                        final item = filteredItems.removeAt(old);
                        filteredItems.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (_, i) {
                      final item = filteredItems[i];
                      final available = _availability[item.id] ?? item.isAvailable;
                      return _MenuItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        available: available,
                        onToggleAvailability: () => setState(() => _availability[item.id] = !available),
                        onEdit: () => _showEditDialog(item),
                        onDelete: () => _showDeleteDialog(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload Menu CSV'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, size: 48, color: AppTheme.primaryRed),
            SizedBox(height: 16),
            Text('Upload your menu in CSV format'),
            SizedBox(height: 8),
            Text('Format: Name, Description, Price, Category, IsVeg', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          PrimaryButton(text: 'Choose File', onPressed: () {}),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _showItemDialog();
  }

  void _showEditDialog(MenuItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({MenuItem? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    bool isVeg = item?.isVeg ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  hintText: 'Item Name',
                  prefixIcon: Icons.restaurant_rounded,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: descController,
                  hintText: 'Description',
                  prefixIcon: Icons.description_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: priceController,
                  hintText: 'Price',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: categoryController,
                  hintText: 'Category',
                  prefixIcon: Icons.category_rounded,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Vegetarian'),
                  subtitle: const Text('Mark as veg item'),
                  value: isVeg,
                  onChanged: (v) => setDialogState(() => isVeg = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            PrimaryButton(
              text: isEdit ? 'Update' : 'Save',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Item updated' : 'Item added'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.removeWhere((i) => i.id == item.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted'),
                  backgroundColor: Color(0xFF2ECC71),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE23744), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final bool available;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemCard({
    super.key,
    required this.item,
    required this.available,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_rounded, color: Colors.grey, size: 30),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegIndicator(isVeg: item.isVeg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryRed),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Actions
            Column(
              children: [
                Switch(
                  value: available,
                  onChanged: (_) => onToggleAvailability(),
                  activeColor: const Color(0xFF2ECC71),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: onEdit,
                      color: Colors.grey[600],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 20),
                      onPressed: onDelete,
                      color: const Color(0xFFE23744),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
