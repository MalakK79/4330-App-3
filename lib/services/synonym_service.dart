import 'dart:math';

import '../data/synonym_list.dart';
import '../models/synonym_puzzle.dart';

/// Supplies the answer-and-clue pair for a Synonym round, and validates
/// typed guesses.
///
/// Answers are drawn at random from the bundled [kSynonymPuzzles] list, so
/// the game is endlessly replayable and works offline — same approach as
/// [RandomWordService], but the pool has to be its own list because every
/// answer needs a clue attached.
class SynonymService {
  SynonymService({List<SynonymPuzzle>? puzzles, Random? random})
      : _puzzles = puzzles ?? kSynonymPuzzles,
        _random = random ?? Random();

  final List<SynonymPuzzle> _puzzles;
  final Random _random;

  static const int wordLength = 5;

  /// A random puzzle.
  ///
  /// [avoid] (normally the word just finished) is never returned twice in a
  /// row, so "New Word" always feels like a new puzzle.
  SynonymPuzzle nextPuzzle({String? avoid}) {
    if (_puzzles.isEmpty) {
      throw StateError('Synonym list is empty — cannot start a round.');
    }
    final skip = avoid?.toUpperCase();
    // With a one-puzzle list there is nothing else to pick, so the "avoid"
    // request is unsatisfiable and gets ignored rather than looping forever.
    if (_puzzles.length == 1) return _puzzles.first;

    while (true) {
      final candidate = _puzzles[_random.nextInt(_puzzles.length)];
      if (candidate.word.toUpperCase() != skip) return candidate;
    }
  }

  /// The puzzle whose answer is [word], or null if the list has no such
  /// entry. Used to restore the clue for a round resumed from storage.
  SynonymPuzzle? puzzleFor(String word) {
    final target = word.toUpperCase();
    for (final puzzle in _puzzles) {
      if (puzzle.word.toUpperCase() == target) return puzzle;
    }
    return null;
  }

  /// Whether [guess] may be submitted.
  ///
  /// Any 5-letter alphabetic input is accepted rather than only words from
  /// the puzzle list — that list is small, and rejecting real words the
  /// player knows is more frustrating than allowing the occasional nonsense
  /// guess. Matches the Wordle game's rule so both boards behave the same.
  bool isValidGuess(String guess) {
    return RegExp(r'^[A-Z]{5}$').hasMatch(guess.toUpperCase());
  }
}
