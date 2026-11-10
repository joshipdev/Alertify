import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertify/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch shows the guide before sign-in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AlertifyApp());

    expect(find.text('Alertify'), findsOneWidget);
    expect(find.text('Home Alert System\nWith Mobile Access'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text("See what's happening at home"), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review alerts and controls'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Connect your hardware'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Secure Your Home,\nAnywhere'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('returning users go directly to sign-in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_getting_started': true});
    await tester.pumpWidget(const AlertifyApp());

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    expect(find.text('GETTING STARTED'), findsNothing);
    expect(find.text('Secure Your Home,\nAnywhere'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
