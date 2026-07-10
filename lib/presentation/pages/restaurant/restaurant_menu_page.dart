import 'package:flutter/material.dart';

class RestaurantMenuPage extends StatefulWidget {
  const RestaurantMenuPage({super.key});

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  final List<MenuItem> _menuItems = [
    MenuItem(
      id: '1',
      name: 'Margherita Pizza',
      category: 'Pizza',
      price: 12.99,
      description: 'Classic tomato sauce, mozzarella, basil',
      isVegetarian: true,
      isAvailable: true,
    ),
    MenuItem(
      id: '2',
      name: 'Pepperoni Pizza',
      category: 'Pizza',
      price: 14.99,
      description: 'Tomato sauce, mozzarella, pepperoni',
      isVegetarian: false,
      isAvailable: true,
    ),
    MenuItem(
      id: '3',
      name: 'Caesar Salad',
      category: 'Salads',
      price: 8.99,
      description: 'Romaine lettuce, croutons, parmesan',
      isVegetarian: true,
      isAvailable: true,
    ),
  ];

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Pizza',
    'Pasta',
    'Salads',
    'Appetizers',
    'Desserts',
    'Beverages',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMenuItemDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItemCard(_filteredItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFFE23744),
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isVegetarian)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.green,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE23744),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Switch(
                  value: item.isAvailable,
                  onChanged: (value) {
                    setState(() {
                      item.isAvailable = value;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditMenuItemDialog(item);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () {
                    _showDeleteDialog(item);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddMenuItemDialog(),
    );
  }

  void _showEditMenuItemDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AddMenuItemDialog(item: item),
    );
  }

  void _showDeleteDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _menuItems.remove(item);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final String id;
  String name;
  String category;
  double price;
  String description;
  bool isVegetarian;
  bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.isVegetarian,
    required this.isAvailable,
  });
}

class AddMenuItemDialog extends StatefulWidget {
  final MenuItem? item;

  const AddMenuItemDialog({super.key, this.item});

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isVegetarian = true;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _categoryController.text = widget.item!.category;
      _priceController.text = widget.item!.price.toString();
      _descriptionController.text = widget.item!.description;
      _isVegetarian = widget.item!.isVegetarian;
      _isAvailable = widget.item!.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isVegetarian,
                  onChanged: (value) {
                    setState(() {
                      _isVegetarian = value ?? false;
                    });
                  },
                ),
                const Text('Vegetarian'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value ?? false;
                    });
                  },
                ),
                const Text('Available'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
