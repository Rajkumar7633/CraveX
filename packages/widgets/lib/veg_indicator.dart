import 'package:flutter/material.dart';

class VegIndicator extends StatelessWidget {
  final bool isVeg;
  final double size;

  const VegIndicator({super.key, required this.isVeg, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: isVeg ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
