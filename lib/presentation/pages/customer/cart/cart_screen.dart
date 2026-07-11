import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zomato_clone/core/theme/app_theme.dart';
import 'package:zomato_clone/presentation/pages/customer/cart/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartItem> _cartItems = [
    CartItem(
      name: 'Hyderabadi Chicken Biryani',
      price: 280,
      quantity: 2,
      isVeg: false,
    ),
    CartItem(
      name: 'Butter Chicken',
      price: 240,
      quantity: 1,
      isVeg: false,
    ),
    CartItem(
      name: 'Veg Manchurian',
      price: 140,
      quantity: 1,
      isVeg: true,
    ),
  ];

  String? _appliedCoupon;
  double _tipAmount = 0;

  double get _subtotal => _cartItems.fold(
      0, (sum, item) => sum + (item.price * item.quantity));

  double get _deliveryFee => 40;
  double get _platformFee => 5;
  double get _packagingCharge => 10;
  double get _tax => (_subtotal * 0.05);
  double get _total => _subtotal + _deliveryFee + _platformFee + _packagingCharge + _tax + _tipAmount;

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
          'Your Cart',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Cart Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Restaurant Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Paradise Biryani',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Add more items',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cart Items List
                ..._cartItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _CartItemTile(
                    item: item,
                    onQuantityChanged: (quantity) {
                      setState(() {
                        if (quantity == 0) {
                          _cartItems.removeAt(index);
                        } else {
                          _cartItems[index] = CartItem(
                            name: item.name,
                            price: item.price,
                            quantity: quantity,
                            isVeg: item.isVeg,
                          );
                        }
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),

                // Coupon Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Apply coupon code',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_appliedCoupon != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Applied',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _appliedCoupon = null);
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            setState(() => _appliedCoupon = 'SAVE50');
                          },
                          child: Text(
                            'Apply',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tip Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.volunteer_activism_outlined,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tip your delivery partner',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TipChip(
                            amount: 0,
                            isSelected: _tipAmount == 0,
                            onTap: () => setState(() => _tipAmount = 0),
                          ),
                          const SizedBox(width: 8),
                          _TipChip(
                            amount: 20,
                            isSelected: _tipAmount == 20,
                            onTap: () => setState(() => _tipAmount = 20),
                          ),
                          const SizedBox(width: 8),
                          _TipChip(
                            amount: 40,
                            isSelected: _tipAmount == 40,
                            onTap: () => setState(() => _tipAmount = 40),
                          ),
                          const SizedBox(width: 8),
                          _TipChip(
                            amount: 60,
                            isSelected: _tipAmount == 60,
                            onTap: () => setState(() => _tipAmount = 60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bill Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _BillRow(
                  label: 'Item Total',
                  value: '₹${_subtotal.toInt()}',
                ),
                const SizedBox(height: 8),
                _BillRow(
                  label: 'Delivery Fee',
                  value: '₹$_deliveryFee',
                ),
                const SizedBox(height: 8),
                _BillRow(
                  label: 'Platform Fee',
                  value: '₹$_platformFee',
                ),
                const SizedBox(height: 8),
                _BillRow(
                  label: 'Packaging Charge',
                  value: '₹$_packagingCharge',
                ),
                const SizedBox(height: 8),
                _BillRow(
                  label: 'Tax (5% GST)',
                  value: '₹${_tax.toStringAsFixed(2)}',
                ),
                if (_tipAmount > 0) ...[
                  const SizedBox(height: 8),
                  _BillRow(
                    label: 'Tip',
                    value: '₹$_tipAmount',
                  ),
                ],
                if (_appliedCoupon != null) ...[
                  const SizedBox(height: 8),
                  _BillRow(
                    label: 'Coupon Discount',
                    value: '-₹50',
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'To Pay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '₹${(_total - (_appliedCoupon != null ? 50 : 0)).toInt()}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Proceed to Checkout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CheckoutScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Proceed to Checkout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final String name;
  final double price;
  final int quantity;
  final bool isVeg;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.isVeg,
  });
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;

  const _CartItemTile({
    required this.item,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          // Veg Icon
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: item.isVeg ? AppTheme.successColor : AppTheme.errorColor,
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

          // Item Name and Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    item.quantity.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _TipChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          amount == 0 ? 'No tip' : '₹$amount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;

  const _BillRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDiscount ? AppTheme.successColor : AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
