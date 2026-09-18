import 'package:flutter/foundation.dart';

import '../models/scramble_status.dart';
import '../services/word_scramble_service.dart';

/// Holds and drives all state for a round of Word Scramble: the target
/// word, its scrambled display order, the player's current guess, and
/// win status.
///
/// OUTLINE ONLY: this is the skeleton for the game — a working round with
/// no attempt limit and no persisted scoreboard yet. Those get layered in
/// once the fail conditions and scoring rules are decided, the same way
/// [GameProvider] layers hard mode and stats on top of its core loop.
class ScrambleProvider extends ChangeNotifier {
  ScrambleProvider({WordScrambleService? wordService})
      : _wordService = wordService ?? WordScrambleService();

  final WordScrambleService _wordService;

  String _targetWord = '';
  String _scrambledWord = '';
  String _currentInput = '';
  ScrambleStatus _status = ScrambleStatus.playing;

  /// One-shot, human-readable message (e.g. "Not quite — try again"). The
  /// UI shows it and then calls [clearError], same pattern as GameProvider.
  String? _errorMessage;

  String get targetWord => _targetWord;
  String get scrambledWord => _scrambledWord;
  String get currentInput => _currentInput;
  ScrambleStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get canEdit => _status == ScrambleStatus.playing;

  /// Draws the first word. Call once when the screen is created.
  void init() {
    _startRound(_wordService.nextWord());
  }

  /// Deals a brand-new word, abandoning the current one if unsolved.
  void newWord() {
    _startRound(_wordService.nextWord(avoid: _targetWord));
    notifyListeners();
  }

  void _startRound(String word) {
    _targetWord = word;
    _scrambledWord = _wordService.scramble(word);
    _currentInput = '';
    _status = ScrambleStatus.playing;
    _errorMessage = null;
  }

  void updateInput(String value) {
    if (!canEdit) return;
    _currentInput = value.toUpperCase();
    notifyListeners();
  }

  void submitGuess() {
    if (!canEdit) return;

    if (_currentInput.isEmpty) {
      _errorMessage = 'Type your guess first';
      notifyListeners();
      return;
    }

    if (_currentInput == _targetWord) {
      _status = ScrambleStatus.won;
    } else {
      // TODO: once fail conditions are defined, count this attempt and set
      // ScrambleStatus.lost when the limit is reached instead of just
      // showing an error and letting the player try again indefinitely.
      _errorMessage = 'Not quite — try again';
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }
}
