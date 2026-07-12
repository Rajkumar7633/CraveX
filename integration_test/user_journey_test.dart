import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zomato_clone/main.dart' as app;
import 'package:zomato_clone/presentation/bloc/auth/auth_bloc.dart';
import 'package:zomato_clone/presentation/bloc/cart/advanced_cart_bloc.dart';
import 'package:zomato_clone/presentation/bloc/order/advanced_order_bloc.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Journey Integration Tests', () {
    testWidgets('complete user journey: login → browse → add to cart → checkout', (WidgetTester tester) async {
      await tester.pumpWidget(app.ZomatoCloneApp());
      await tester.pumpAndSettle();

      // Step 1: Login with phone number
      expect(find.text('Login'), findsOneWidget);
      await tester.enterText(find.byKey(Key('phone_input')), '+919876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // Step 2: Enter OTP (simulated)
      await tester.enterText(find.byKey(Key('otp_input')), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Step 3: Browse restaurants
      expect(find.text('Restaurants'), findsOneWidget);
      await tester.tap(find.text('Search restaurants'));
      await tester.pumpAndSettle();

      // Step 4: Select a restaurant
      await tester.tap(find.text('Test Restaurant'));
      await tester.pumpAndSettle();

      // Step 5: Add item to cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Verify cart badge shows item count
      expect(find.text('1'), findsOneWidget);

      // Step 6: View cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Verify cart shows item
      expect(find.text('Test Item'), findsOneWidget);

      // Step 7: Proceed to checkout
      await tester.tap(find.text('Proceed to Checkout'));
      await tester.pumpAndSettle();

      // Step 8: Fill delivery address
      await tester.enterText(find.byKey(Key('address_field')), '123 Test Street');
      await tester.pumpAndSettle();

      // Step 9: Select payment method
      await tester.tap(find.text('UPI'));
      await tester.pumpAndSettle();

      // Step 10: Place order
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Verify order confirmation
      expect(find.text('Order Placed Successfully'), findsOneWidget);
    });

    testWidgets('handles order tracking flow', (WidgetTester tester) async {
      await tester.pumpWidget(app.ZomatoCloneApp());
      await tester.pumpAndSettle();

      // Login (skip for brevity - assume already logged in)
      // Navigate to orders
      await tester.tap(find.byIcon(Icons.receipt_long));
      await tester.pumpAndSettle();

      // Tap on an order to track
      await tester.tap(find.text('Order #12345'));
      await tester.pumpAndSettle();

      // Verify tracking screen shows
      expect(find.text('Order Tracking'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
    });

    testWidgets('handles order cancellation flow', (WidgetTester tester) async {
      await tester.pumpWidget(app.ZomatoCloneApp());
      await tester.pumpAndSettle();

      // Navigate to orders
      await tester.tap(find.byIcon(Icons.receipt_long));
      await tester.pumpAndSettle();

      // Tap on an active order
      await tester.tap(find.text('Order #12345'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      // Select cancellation reason
      await tester.tap(find.text('Changed my mind'));
      await tester.pumpAndSettle();

      // Confirm cancellation
      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();

      // Verify cancellation
      expect(find.text('Order Cancelled'), findsOneWidget);
    });

    testWidgets('handles search and filter flow', (WidgetTester tester) async {
      await tester.pumpWidget(app.ZomatoCloneApp());
      await tester.pumpAndSettle();

      // Tap search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byKey(Key('search_field')), 'Pizza');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Pizza Hut'), findsOneWidget);

      // Apply filter
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // Select cuisine filter
      await tester.tap(find.text('Italian'));
      await tester.pumpAndSettle();

      // Apply filter
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('Italian Restaurants'), findsOneWidget);
    });

    testWidgets('handles profile update flow', (WidgetTester tester) async {
      await tester.pumpWidget(app.ZomatoCloneApp());
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Tap edit profile
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Update name
      await tester.enterText(find.byKey(Key('name_field')), 'John Doe');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Profile Updated'), findsOneWidget);
    });
  });
}
