import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<String> steps;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    this.steps = AppOrderStatus.customerSteps,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = steps.indexOf(currentStatus);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;
        final isDone = idx <= currentIdx;
        final isActive = idx == currentIdx;
        final isLast = idx == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.primaryRed : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDone && idx < currentIdx ? AppTheme.primaryRed : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppOrderStatus.labels[step] ?? step,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (isActive)
                      Text('In progress...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
