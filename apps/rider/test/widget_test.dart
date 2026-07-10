import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/main.dart';

void main() {
  testWidgets('RiderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RiderApp());
    expect(true, true);
  });
}
