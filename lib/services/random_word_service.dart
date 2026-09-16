import 'dart:math';

import '../data/word_list.dart';

/// Supplies the answer for a round and validates typed guesses.
///
/// Unlike a "word of the day" scheme, every round draws a fresh answer at
/// random from the bundled list, so the game can be replayed as many times
/// as the player wants. The list is local, so this works offline.
class RandomWordService {
  RandomWordService({List<String>? words, Random? random})
      : _words = words ?? kWordList,
        _random = random ?? Random();

  final List<String> _words;
  final Random _random;

  static const int wordLength = 5;

  /// A random answer word, uppercase.
  ///
  /// [avoid] (normally the word just finished) is never returned twice in a
  /// row, so "New Word" always feels like a new puzzle. Pass null/empty to
  /// draw from the whole list.
  String nextWord({String? avoid}) {
    if (_words.isEmpty) {
      throw StateError('Word list is empty — cannot start a round.');
    }
    final skip = avoid?.toUpperCase();
    // With a one-word list there is nothing else to pick, so the "avoid"
    // request is unsatisfiable and gets ignored rather than looping forever.
    if (_words.length == 1) return _words.first.toUpperCase();

    while (true) {
      final candidate = _words[_random.nextInt(_words.length)].toUpperCase();
      if (candidate != skip) return candidate;
    }
  }

  /// Whether [guess] may be submitted.
  ///
  /// Any 5-letter alphabetic input is accepted rather than only words from
  /// the bundled answer list — that list is small, and rejecting real words
  /// the player knows is more frustrating than allowing the occasional
  /// nonsense guess. Swap in a full dictionary here for stricter play.
  bool isValidGuess(String guess) {
    return RegExp(r'^[A-Z]{5}$').hasMatch(guess.toUpperCase());
  }
}
