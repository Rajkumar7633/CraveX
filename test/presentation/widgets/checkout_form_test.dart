import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zomato_clone/presentation/widgets/checkout_form_widget.dart';

void main() {
  group('CheckoutFormWidget Tests', () {
    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutFormWidget(
              onSubmit: (data) {},
            ),
          ),
        ),
      );

      // Try to submit without filling required fields
      final submitButton = find.text('Place Order');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('Delivery address is required'), findsOneWidget);
      expect(find.text('Payment method is required'), findsOneWidget);
    });

    testWidgets('validates phone number format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutFormWidget(
              onSubmit: (data) {},
            ),
          ),
        ),
      );

      // Enter invalid phone number
      final phoneField = find.byKey(Key('phone_field'));
      await tester.enterText(phoneField, '123');
      await tester.pump();

      final submitButton = find.text('Place Order');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show phone validation error
      expect(find.text('Invalid phone number'), findsOneWidget);
    });

    testWidgets('validates email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutFormWidget(
              onSubmit: (data) {},
            ),
          ),
        ),
      );

      // Enter invalid email
      final emailField = find.byKey(Key('email_field'));
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();

      final submitButton = find.text('Place Order');
      await tester.tap(submitButton);
      await tester.pump();

      // Should show email validation error
      expect(find.text('Invalid email address'), findsOneWidget);
    });

    testWidgets('accepts valid form data', (WidgetTester tester) async {
      bool submitted = false;
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutFormWidget(
              onSubmit: (data) {
                submitted = true;
                submittedData = data;
              },
            ),
          ),
        ),
      );

      // Fill valid form data
      await tester.enterText(find.byKey(Key('address_field')), '123 Test Street');
      await tester.enterText(find.byKey(Key('phone_field')), '+919876543210');
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.pump();

      // Select payment method
      await tester.tap(find.text('UPI'));
      await tester.pump();

      // Submit form
      await tester.tap(find.text('Place Order'));
      await tester.pump();

      expect(submitted, true);
      expect(submittedData?['address'], '123 Test Street');
      expect(submittedData?['phone'], '+919876543210');
      expect(submittedData?['payment_method'], 'UPI');
    });

    testWidgets('shows loading state during submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutFormWidget(
              onSubmit: (data) {
                // Simulate async submission
                Future.delayed(Duration(seconds: 1));
              },
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Place Order'), findsNothing);
    });
  });
}
