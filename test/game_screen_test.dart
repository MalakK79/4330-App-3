import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_puzzler/providers/game_provider.dart';
import 'package:daily_puzzler/screens/game_screen.dart';
import 'package:daily_puzzler/services/random_word_service.dart';

/// Drives the real game screen against a two-word list, so the answer is
/// predictable and "new word" has somewhere to go.
Future<GameProvider> pumpGame(WidgetTester tester) async {
  final provider = GameProvider(
    wordService: RandomWordService(words: ['CRANE', 'SLATE']),
  );
  await provider.init();

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

Future<void> guessWord(
  WidgetTester tester,
  GameProvider provider,
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

  testWidgets('losing reveals the word and offers a new one', (tester) async {
    final provider = await pumpGame(tester);
    final answer = provider.targetWord;

    for (var i = 0; i < GameProvider.maxGuesses; i++) {
      await guessWord(tester, provider, 'ZZZZZ');
    }

    expect(find.text('Out of guesses'), findsOneWidget);
    // The answer is shown in the dialog.
    expect(find.text(answer), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // ...and stays on the board, next to the new-word button.
    expect(find.text('The word was $answer'), findsOneWidget);

    await tester.tap(find.text('New Word'));
    await tester.pumpAndSettle();

    expect(provider.targetWord, isNot(answer));
    expect(provider.guesses, isEmpty);
    expect(find.text('STREAK 0'), findsOneWidget);
  });
}
