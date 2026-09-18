import 'package:flutter_test/flutter_test.dart';
import 'package:navcore_mobile/main.dart';

void main() {
  testWidgets('NavCore mobile app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NavCoreApp());
    expect(find.text('NavCore'), findsWidgets);
  });
}
