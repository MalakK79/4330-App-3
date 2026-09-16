import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_puzzler/main.dart';

void main() {
  setUp(() {
    // Avoids MissingPluginException for shared_preferences in widget tests.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and shows the welcome screen', (tester) async {
    await tester.pumpWidget(const DailyPuzzlerApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('DAILY PUZZLER'), findsOneWidget);
    expect(find.text('WORDLE'), findsOneWidget);
  });

  testWidgets('Tapping Wordle opens the game screen with a streak counter',
      (tester) async {
    await tester.pumpWidget(const DailyPuzzlerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('WORDLE'));
    await tester.pumpAndSettle();

    expect(find.text('ENTER'), findsOneWidget);
    expect(find.text('STREAK 0'), findsOneWidget);
  });
}
