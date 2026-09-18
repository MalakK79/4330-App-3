import 'dart:math';

import '../data/word_list.dart';

/// Supplies the answer word for a Word Scramble round and shuffles its
/// letters for display.
///
/// Reuses the same bundled [kWordList] as Wordle, so both puzzles share one
/// offline word source. Swap in a dedicated scramble word list later
/// (e.g. if you want longer or easier words than the 5-letter Wordle list)
/// without touching [ScrambleProvider].
class WordScrambleService {
  WordScrambleService({List<String>? words, Random? random})
      : _words = words ?? kWordList,
        _random = random ?? Random();

  final List<String> _words;
  final Random _random;

  /// A random answer word, uppercase.
  ///
  /// [avoid] (normally the word just finished) is never returned twice in a
  /// row, mirroring [RandomWordService.nextWord] from the Wordle game.
  String nextWord({String? avoid}) {
    if (_words.isEmpty) {
      throw StateError('Word list is empty — cannot start a round.');
    }
    final skip = avoid?.toUpperCase();
    if (_words.length == 1) return _words.first.toUpperCase();

    while (true) {
      final candidate = _words[_random.nextInt(_words.length)].toUpperCase();
      if (candidate != skip) return candidate;
    }
  }

  /// Shuffles [word]'s letters into a random order that isn't the original
  /// word itself, so the puzzle is never trivially "already solved".
  String scramble(String word) {
    if (word.length <= 1) return word;
    final letters = word.split('');
    String shuffled;
    do {
      letters.shuffle(_random);
      shuffled = letters.join();
    } while (shuffled == word);
    return shuffled;
  }
}
