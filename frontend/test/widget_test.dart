import 'package:flutter_test/flutter_test.dart';
import 'package:mediminder/main.dart';

void main() {
  testWidgets('MediMinder app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MediMinderApp());
    // Splash screen should appear
    expect(find.text('MediMinder'), findsOneWidget);
  });
}
