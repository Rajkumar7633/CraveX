import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'veg_indicator.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  final int quantity;

  const MenuItemTile({
    super.key,
    required this.item,
    required this.onAdd,
    this.quantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegIndicator(isVeg: item.isVeg),
                    if (item.isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Bestseller', style: TextStyle(fontSize: 10, color: AppTheme.gold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('₹${item.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              quantity > 0
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryRed),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: onAdd,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: onAdd,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton(
                      onPressed: item.isAvailable ? onAdd : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryRed,
                        side: const BorderSide(color: AppTheme.primaryRed),
                        minimumSize: const Size(80, 32),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(item.isAvailable ? 'ADD' : 'UNAVAIL', style: const TextStyle(fontSize: 12)),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
