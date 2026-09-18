import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_puzzler/models/synonym_puzzle.dart';
import 'package:daily_puzzler/providers/synonym_provider.dart';
import 'package:daily_puzzler/screens/synonym_screen.dart';
import 'package:daily_puzzler/services/synonym_service.dart';

const _angry = SynonymPuzzle('ANGRY', 'Furious');
const _quiet = SynonymPuzzle('QUIET', 'Silent');

/// Drives the real screen against a two-puzzle list, so the answer is
/// predictable and "new word" has somewhere to go.
Future<SynonymProvider> pumpGame(WidgetTester tester) async {
  final provider = SynonymProvider(
    synonymService: SynonymService(puzzles: [_angry, _quiet]),
  );
  await provider.init();

  await tester.pumpWidget(
    ChangeNotifierProvider<SynonymProvider>.value(
      value: provider,
      child: const MaterialApp(home: SynonymScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

Future<void> guessWord(
  WidgetTester tester,
  SynonymProvider provider,
  String word,
) async {
  for (final letter in word.split('')) {
    provider.addLetter(letter);
  }
  await provider.submitGuess();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the clue and a streak counter above the board',
      (tester) async {
    final provider = await pumpGame(tester);

    expect(find.text('FIND A WORD MEANING'), findsOneWidget);
    expect(find.text(provider.clue.toUpperCase()), findsOneWidget);
    expect(find.text('STREAK 0'), findsOneWidget);
    expect(find.text('ENTER'), findsOneWidget);
    // The clue is the only hint — the answer stays hidden while playing.
    expect(find.text(provider.targetWord), findsNothing);
  });

  testWidgets('board, clue, and keyboard all fit a narrow phone',
      (tester) async {
    // The clue banner is extra height on an already-tight screen, so check
    // a small phone surface: any overflow would fail this test.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpGame(tester);

    expect(find.text('FIND A WORD MEANING'), findsOneWidget);
    expect(find.text('ENTER'), findsOneWidget);
  });

  testWidgets('winning offers another word and advances the streak',
      (tester) async {
    final provider = await pumpGame(tester);
    await guessWord(tester, provider, provider.targetWord);

    expect(find.text('You got it! 🎉'), findsOneWidget);
    expect(find.text('Streak: 1 in a row'), findsOneWidget);

    // "Next Word" is also on the round-over bar behind the dialog, so aim
    // at the dialog's copy specifically.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Next Word'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('You got it! 🎉'), findsNothing);
    expect(provider.guesses, isEmpty);
    expect(find.text('STREAK 1'), findsOneWidget);
  });

  testWidgets('losing reveals the word and what it meant', (tester) async {
    final provider = await pumpGame(tester);
    final answer = provider.targetWord;
    final clue = provider.clue;

    for (var i = 0; i < SynonymProvider.maxGuesses; i++) {
      await guessWord(tester, provider, 'ZZZZZ');
    }

    expect(find.text('Out of guesses'), findsOneWidget);
    expect(find.text('$answer means "$clue".'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // ...and the answer stays on the board, next to the new-word button.
    expect(find.text('The word was $answer'), findsOneWidget);

    await tester.tap(find.text('New Word'));
    await tester.pumpAndSettle();

    expect(provider.targetWord, isNot(answer));
    expect(find.text('STREAK 0'), findsOneWidget);
  });
}
