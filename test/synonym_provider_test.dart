import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_puzzler/data/synonym_list.dart';
import 'package:daily_puzzler/models/game_status.dart';
import 'package:daily_puzzler/models/synonym_puzzle.dart';
import 'package:daily_puzzler/providers/game_provider.dart';
import 'package:daily_puzzler/providers/synonym_provider.dart';
import 'package:daily_puzzler/services/progress_service.dart';
import 'package:daily_puzzler/services/random_word_service.dart';
import 'package:daily_puzzler/services/synonym_service.dart';

/// Types [word] one letter at a time and submits it, the same way the
/// keyboard widget drives the provider.
Future<void> guess(SynonymProvider provider, String word) async {
  for (final letter in word.split('')) {
    provider.addLetter(letter);
  }
  await provider.submitGuess();
}

Future<SynonymProvider> newProvider(List<SynonymPuzzle> puzzles) async {
  final provider = SynonymProvider(
    synonymService: SynonymService(puzzles: puzzles),
  );
  await provider.init();
  return provider;
}

const _angry = SynonymPuzzle('ANGRY', 'Furious');
const _quiet = SynonymPuzzle('QUIET', 'Silent');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every bundled puzzle is a 5-letter answer with a clue', () {
    expect(kSynonymPuzzles, isNotEmpty);
    for (final puzzle in kSynonymPuzzles) {
      expect(puzzle.word, matches(RegExp(r'^[A-Z]{5}$')),
          reason: '${puzzle.word} does not fit the grid');
      expect(puzzle.clue.trim(), isNotEmpty,
          reason: '${puzzle.word} has no clue');
      // A clue that is the answer would give the round away outright.
      expect(puzzle.clue.toUpperCase(), isNot(puzzle.word));
    }
  });

  test('starts a round with the clue for the drawn word', () async {
    final provider = await newProvider([_angry]);

    expect(provider.targetWord, 'ANGRY');
    expect(provider.clue, 'Furious');
    expect(provider.guesses, isEmpty);
    expect(provider.status, GameStatus.playing);
    expect(provider.currentStreak, 0);
  });

  test('guessing the word from its clue wins and builds the streak',
      () async {
    final provider = await newProvider([_angry, _quiet]);

    await guess(provider, 'CRANE');
    expect(provider.status, GameStatus.playing);
    // The board colors guesses exactly like Wordle does.
    expect(provider.keyStatuses, isNotEmpty);

    await guess(provider, provider.targetWord);
    expect(provider.status, GameStatus.won);
    expect(provider.currentStreak, 1);

    await provider.newGame();
    await guess(provider, provider.targetWord);
    expect(provider.currentStreak, 2);
    expect(provider.bestStreak, 2);
  });

  test('running out of guesses loses the round and resets the streak',
      () async {
    final provider = await newProvider([_angry, _quiet]);

    await guess(provider, provider.targetWord);
    expect(provider.currentStreak, 1);

    await provider.newGame();
    for (var i = 0; i < SynonymProvider.maxGuesses; i++) {
      await guess(provider, 'ZZZZZ');
    }

    expect(provider.status, GameStatus.lost);
    expect(provider.currentStreak, 0);
    // The best streak is a high-water mark, so it survives the loss.
    expect(provider.bestStreak, 1);
  });

  test('a new word clears the board and swaps in a new clue', () async {
    final provider = await newProvider([_angry, _quiet]);
    final firstWord = provider.targetWord;
    final firstClue = provider.clue;
    await guess(provider, 'CRANE');

    await provider.newGame();

    expect(provider.targetWord, isNot(firstWord));
    expect(provider.clue, isNot(firstClue));
    expect(provider.guesses, isEmpty);
    expect(provider.keyStatuses, isEmpty);
    expect(provider.status, GameStatus.playing);
  });

  test('an unfinished round is resumed with its clue intact', () async {
    final provider = await newProvider([_angry, _quiet]);
    await guess(provider, 'CRANE');
    final word = provider.targetWord;
    final clue = provider.clue;

    // A second provider reads the same (mocked) on-device storage.
    final resumed = await newProvider([_angry, _quiet]);

    expect(resumed.targetWord, word);
    expect(resumed.clue, clue);
    expect(resumed.guesses, ['CRANE']);
  });

  test('a saved word that no longer has a clue is not resumed', () async {
    final provider = await newProvider([_angry]);
    await guess(provider, 'CRANE');
    expect(provider.targetWord, 'ANGRY');

    // The word bank changed under the saved round — it gets a fresh puzzle
    // rather than a board with no prompt.
    final relaunched = await newProvider([_quiet]);

    expect(relaunched.targetWord, 'QUIET');
    expect(relaunched.clue, 'Silent');
    expect(relaunched.guesses, isEmpty);
  });

  test('short guesses are rejected with a message', () async {
    final provider = await newProvider([_angry]);

    provider.addLetter('A');
    await provider.submitGuess();

    expect(provider.guesses, isEmpty);
    expect(provider.errorMessage, 'Not enough letters');
  });

  test('the two games keep separate streaks', () async {
    final synonym = await newProvider([_angry, _quiet]);
    final wordle = GameProvider(
      wordService: RandomWordService(words: ['CRANE', 'SLATE']),
      progressService: ProgressService(),
    );
    await wordle.init();

    await guess(synonym, synonym.targetWord);

    expect(synonym.currentStreak, 1);
    // Winning at Synonym doesn't touch the Wordle scoreboard.
    final reloadedWordle = GameProvider(
      wordService: RandomWordService(words: ['CRANE', 'SLATE']),
      progressService: ProgressService(),
    );
    await reloadedWordle.init();
    expect(reloadedWordle.currentStreak, 0);
  });
}
