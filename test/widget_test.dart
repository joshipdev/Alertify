import 'package:flutter_test/flutter_test.dart';
import 'package:alertify/main.dart';

void main() {
  testWidgets('AlertifyApp renders splash screen and transitions', (WidgetTester tester) async {
    await tester.pumpWidget(const AlertifyApp());

    // Expect splash screen title
    expect(find.text('Alertify'), findsOneWidget);
    expect(find.text('Home Alert System\nWith Mobile Access'), findsOneWidget);

    // Fast-forward past the 2200ms timer
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();

    // Now on login screen
    expect(find.text('Secure Your Home,\nAnywhere'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
