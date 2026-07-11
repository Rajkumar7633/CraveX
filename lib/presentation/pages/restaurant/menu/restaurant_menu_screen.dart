import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zomato_clone/core/theme/app_theme.dart';

class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Menu Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: (index) => setState(() => _selectedTabIndex = index),
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: 'Categories'),
                Tab(text: 'Items'),
                Tab(text: 'Combos'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _CategoriesTab(),
                _ItemsTab(),
                _CombosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CategoryCard(
          name: 'Starters',
          itemCount: 12,
          icon: Icons.fastfood,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          name: 'Biryani',
          itemCount: 8,
          icon: Icons.rice_bowl,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          name: 'Main Course',
          itemCount: 15,
          icon: Icons.dinner_dining,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          name: 'Desserts',
          itemCount: 6,
          icon: Icons.cake,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          name: 'Beverages',
          itemCount: 10,
          icon: Icons.local_cafe,
          onEdit: () {},
          onDelete: () {},
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final int itemCount;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.name,
    required this.itemCount,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            color: AppTheme.textSecondary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuItemCard(
          name: 'Hyderabadi Chicken Biryani',
          category: 'Biryani',
          price: 280,
          isVeg: false,
          isAvailable: true,
          onEdit: () {},
          onToggleAvailability: () {},
        ),
        const SizedBox(height: 12),
        _MenuItemCard(
          name: 'Butter Chicken',
          category: 'Main Course',
          price: 240,
          isVeg: false,
          isAvailable: true,
          onEdit: () {},
          onToggleAvailability: () {},
        ),
        const SizedBox(height: 12),
        _MenuItemCard(
          name: 'Veg Manchurian',
          category: 'Starters',
          price: 140,
          isVeg: true,
          isAvailable: true,
          onEdit: () {},
          onToggleAvailability: () {},
        ),
        const SizedBox(height: 12),
        _MenuItemCard(
          name: 'Mutton Biryani',
          category: 'Biryani',
          price: 320,
          isVeg: false,
          isAvailable: false,
          onEdit: () {},
          onToggleAvailability: () {},
        ),
        const SizedBox(height: 12),
        _MenuItemCard(
          name: 'Paneer Butter Masala',
          category: 'Main Course',
          price: 200,
          isVeg: true,
          isAvailable: true,
          onEdit: () {},
          onToggleAvailability: () {},
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final String name;
  final String category;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

  const _MenuItemCard({
    required this.name,
    required this.category,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppTheme.dividerColor : AppTheme.errorColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Veg Icon
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isVeg ? AppTheme.successColor : AppTheme.errorColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toInt()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Availability Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Out of Stock',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isAvailable
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            color: AppTheme.textSecondary,
          ),
          Switch(
            value: isAvailable,
            onChanged: (_) => onToggleAvailability(),
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }
}

class _CombosTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ComboCard(
          name: 'Family Feast',
          description: '2 Biryani + 1 Starter + 1 Dessert',
          originalPrice: 800,
          discountedPrice: 650,
          items: 4,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _ComboCard(
          name: 'Lunch Special',
          description: '1 Biryani + 1 Curry + 2 Roti',
          originalPrice: 400,
          discountedPrice: 320,
          items: 3,
          onEdit: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _ComboCard(
          name: 'Couple\'s Delight',
          description: '2 Biryani + 1 Starter + 1 Beverage',
          originalPrice: 600,
          discountedPrice: 480,
          items: 4,
          onEdit: () {},
          onDelete: () {},
        ),
      ],
    );
  }
}

class _ComboCard extends StatelessWidget {
  final String name;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final int items;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ComboCard({
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final discount = ((originalPrice - discountedPrice) / originalPrice * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$discount% OFF',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${originalPrice.toInt()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${discountedPrice.toInt()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$items items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                color: AppTheme.textSecondary,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
