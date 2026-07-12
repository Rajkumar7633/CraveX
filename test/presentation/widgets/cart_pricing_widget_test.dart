import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zomato_clone/presentation/widgets/cart_pricing_widget.dart';
import 'package:zomato_clone/domain/entities/cart_item.dart';

void main() {
  group('CartPricingWidget Tests', () {
    testWidgets('displays correct item total', (WidgetTester tester) async {
      final cartItems = [
        CartItem(
          id: '1',
          menuItemId: 'item1',
          name: 'Burger',
          quantity: 2,
          unitPrice: 100.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartPricingWidget(
              cartItems: cartItems,
              restaurantId: 'rest1',
              deliveryAddress: 'Test Address',
            ),
          ),
        ),
      );

      expect(find.text('₹200'), findsOneWidget);
    });

    testWidgets('calculates GST correctly', (WidgetTester tester) async {
      final cartItems = [
        CartItem(
          id: '1',
          menuItemId: 'item1',
          name: 'Burger',
          quantity: 1,
          unitPrice: 100.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartPricingWidget(
              cartItems: cartItems,
              restaurantId: 'rest1',
              deliveryAddress: 'Test Address',
            ),
          ),
        ),
      );

      // GST on food is 5%, so ₹100 + ₹5 GST = ₹105
      expect(find.text('₹105'), findsOneWidget);
    });

    testWidgets('handles empty cart gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartPricingWidget(
              cartItems: [],
              restaurantId: 'rest1',
              deliveryAddress: 'Test Address',
            ),
          ),
        ),
      );

      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('applies coupon discount correctly', (WidgetTester tester) async {
      final cartItems = [
        CartItem(
          id: '1',
          menuItemId: 'item1',
          name: 'Burger',
          quantity: 1,
          unitPrice: 100.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartPricingWidget(
              cartItems: cartItems,
              restaurantId: 'rest1',
              deliveryAddress: 'Test Address',
              couponCode: 'SAVE20',
            ),
          ),
        ),
      );

      // Should show discount applied
      expect(find.textContaining('Discount'), findsOneWidget);
    });

    testWidgets('validates minimum order value', (WidgetTester tester) async {
      final cartItems = [
        CartItem(
          id: '1',
          menuItemId: 'item1',
          name: 'Small Item',
          quantity: 1,
          unitPrice: 50.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartPricingWidget(
              cartItems: cartItems,
              restaurantId: 'rest1',
              deliveryAddress: 'Test Address',
            ),
          ),
        ),
      );

      // Should show minimum order warning
      expect(find.textContaining('minimum order'), findsOneWidget);
    });
  });
}
