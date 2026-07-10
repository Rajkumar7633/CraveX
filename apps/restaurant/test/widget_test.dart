import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/main.dart';

void main() {
  testWidgets('RestaurantApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantApp());
    expect(true, true);
  });
}
