import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_puzzler/models/game_status.dart';
import 'package:daily_puzzler/providers/game_provider.dart';
import 'package:daily_puzzler/services/random_word_service.dart';

/// Types [word] one letter at a time and submits it, the same way the
/// keyboard widget drives the provider.
Future<void> guess(GameProvider provider, String word) async {
  for (final letter in word.split('')) {
    provider.addLetter(letter);
  }
  await provider.submitGuess();
}

Future<GameProvider> newProvider(List<String> words) async {
  final provider = GameProvider(
    wordService: RandomWordService(words: words),
  );
  await provider.init();
  return provider;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts a round with a word drawn from the list', () async {
    final provider = await newProvider(['CRANE']);

    expect(provider.targetWord, 'CRANE');
    expect(provider.guesses, isEmpty);
    expect(provider.status, GameStatus.playing);
    expect(provider.currentStreak, 0);
  });

  test('running out of guesses loses the round and keeps the answer',
      () async {
    final provider = await newProvider(['CRANE']);

    for (var i = 0; i < GameProvider.maxGuesses; i++) {
      await guess(provider, 'SPOIL');
    }

    expect(provider.status, GameStatus.lost);
    expect(provider.isRoundOver, isTrue);
    // The UI reveals this to the player when the round is lost.
    expect(provider.targetWord, 'CRANE');
    expect(provider.currentStreak, 0);
  });

  test('a seventh guess is refused once the round is over', () async {
    final provider = await newProvider(['CRANE']);

    for (var i = 0; i < GameProvider.maxGuesses; i++) {
      await guess(provider, 'SPOIL');
    }
    await guess(provider, 'CRANE');

    expect(provider.guesses.length, GameProvider.maxGuesses);
    expect(provider.status, GameStatus.lost);
  });

  test('solving builds the streak, and a loss resets it', () async {
    final provider = await newProvider(['CRANE', 'SLATE']);

    await guess(provider, provider.targetWord);
    expect(provider.status, GameStatus.won);
    expect(provider.currentStreak, 1);

    await provider.newGame();
    await guess(provider, provider.targetWord);
    expect(provider.currentStreak, 2);
    expect(provider.bestStreak, 2);

    await provider.newGame();
    for (var i = 0; i < GameProvider.maxGuesses; i++) {
      await guess(provider, 'ZZZZZ');
    }
    expect(provider.status, GameStatus.lost);
    expect(provider.currentStreak, 0);
    // The best streak is a high-water mark, so it survives the loss.
    expect(provider.bestStreak, 2);
  });

  test('a new word clears the board and never repeats the last answer',
      () async {
    final provider = await newProvider(['CRANE', 'SLATE']);
    final firstWord = provider.targetWord;
    await guess(provider, 'SPOIL');

    await provider.newGame();

    expect(provider.targetWord, isNot(firstWord));
    expect(provider.guesses, isEmpty);
    expect(provider.evaluations, isEmpty);
    expect(provider.keyStatuses, isEmpty);
    expect(provider.currentInput, '');
    expect(provider.status, GameStatus.playing);
  });

  test('an unfinished round is resumed on relaunch', () async {
    final provider = await newProvider(['CRANE', 'SLATE']);
    await guess(provider, 'SPOIL');
    final word = provider.targetWord;

    // A second provider reads the same (mocked) on-device storage.
    final resumed = await newProvider(['CRANE', 'SLATE']);

    expect(resumed.targetWord, word);
    expect(resumed.guesses, ['SPOIL']);
  });

  test('a finished round is not resumed — relaunching deals a fresh word',
      () async {
    final provider = await newProvider(['CRANE']);
    await guess(provider, 'CRANE');

    final relaunched = await newProvider(['CRANE']);

    expect(relaunched.guesses, isEmpty);
    expect(relaunched.status, GameStatus.playing);
    // The streak it earned is still there, though.
    expect(relaunched.currentStreak, 1);
  });

  test('short guesses are rejected with a message', () async {
    final provider = await newProvider(['CRANE']);

    provider.addLetter('A');
    await provider.submitGuess();

    expect(provider.guesses, isEmpty);
    expect(provider.errorMessage, 'Not enough letters');
  });
}
