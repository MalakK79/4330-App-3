import 'package:flutter/foundation.dart';

import '../models/daily_game_record.dart';
import '../models/game_status.dart';
import '../models/player_stats.dart';
import '../models/tile_status.dart';
import '../services/daily_word_service.dart';
import '../services/guess_evaluator.dart';
import '../services/progress_service.dart';

/// Holds and drives all state for "today's" game: the target word, guesses
/// made so far, on-screen keyboard coloring, win/loss status, hard-mode
/// enforcement, and the persisted stats. The UI layer only reads this and
/// calls its input methods (`addLetter`, `removeLetter`, `submitGuess`).
class GameProvider extends ChangeNotifier {
  GameProvider({
    DailyWordService? wordService,
    ProgressService? progressService,
    DateTime Function()? now,
  })  : _wordService = wordService ?? DailyWordService(),
        _progressService = progressService ?? ProgressService(),
        _now = now ?? DateTime.now;

  static const int wordLength = 5;
  static const int maxGuesses = 6;

  final DailyWordService _wordService;
  final ProgressService _progressService;
  final DateTime Function() _now;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  late String _targetWord;
  late String _dateKey;
  late int _puzzleNumber;

  final List<String> _guesses = [];
  final List<List<TileStatus>> _evaluations = [];
  String _currentInput = '';
  GameStatus _status = GameStatus.playing;
  bool _hardMode = false;
  PlayerStats _stats = PlayerStats();

  /// One-shot, human-readable message for things like "Not enough letters"
  /// or a hard-mode violation. The UI shows it (e.g. a SnackBar) and then
  /// calls [clearError].
  String? _errorMessage;

  final Map<String, TileStatus> _keyStatuses = {};

  // Hard-mode bookkeeping: positions/letters that later guesses must respect.
  final Map<int, String> _requiredPositions = {};
  final Set<String> _requiredLetters = {};

  int get puzzleNumber => _puzzleNumber;
  List<String> get guesses => List.unmodifiable(_guesses);
  List<List<TileStatus>> get evaluations => List.unmodifiable(_evaluations);
  String get currentInput => _currentInput;
  GameStatus get status => _status;
  bool get hardMode => _hardMode;
  PlayerStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  Map<String, TileStatus> get keyStatuses => Map.unmodifiable(_keyStatuses);
  String get targetWord => _targetWord;
  bool get canEdit => _status == GameStatus.playing;
  int get remainingGuesses => maxGuesses - _guesses.length;

  Future<void> init() async {
    final today = _now();
    _dateKey = DailyWordService.dateKey(today);
    _targetWord = _wordService.wordForDate(today);
    _puzzleNumber = _wordService.puzzleNumberForDate(today);

    _hardMode = await _progressService.getHardMode();
    _stats = await _progressService.loadStats();

    final existing = await _progressService.loadTodayRecord(_dateKey);
    if (existing != null) {
      for (final guess in existing.guesses) {
        _applyGuess(guess, persist: false);
      }
      _status = existing.status;
    }

    _isLoading = false;
    notifyListeners();
  }

  void addLetter(String letter) {
    if (!canEdit) return;
    if (_currentInput.length >= wordLength) return;
    _currentInput += letter.toUpperCase();
    notifyListeners();
  }

  void removeLetter() {
    if (!canEdit) return;
    if (_currentInput.isEmpty) return;
    _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    notifyListeners();
  }

  Future<void> setHardMode(bool value) async {
    _hardMode = value;
    await _progressService.setHardMode(value);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> submitGuess() async {
    if (!canEdit) return;

    if (_currentInput.length != wordLength) {
      _errorMessage = 'Not enough letters';
      notifyListeners();
      return;
    }

    if (!_wordService.isValidGuess(_currentInput)) {
      _errorMessage = 'Not a valid word';
      notifyListeners();
      return;
    }

    final hardModeError = _hardMode ? _checkHardMode(_currentInput) : null;
    if (hardModeError != null) {
      _errorMessage = hardModeError;
      notifyListeners();
      return;
    }

    final guess = _currentInput;
    _currentInput = '';
    await _applyGuess(guess, persist: true);
    notifyListeners();
  }

  String? _checkHardMode(String guess) {
    for (final entry in _requiredPositions.entries) {
      if (guess[entry.key] != entry.value) {
        final position = _ordinal(entry.key + 1);
        return 'The $position letter must be ${entry.value}';
      }
    }
    for (final letter in _requiredLetters) {
      if (!guess.contains(letter)) {
        return 'Guess must contain $letter';
      }
    }
    return null;
  }

  String _ordinal(int n) {
    const suffixes = {1: 'st', 2: 'nd', 3: 'rd'};
    return '$n${suffixes[n] ?? 'th'}';
  }

  Future<void> _applyGuess(String guess, {required bool persist}) async {
    final evaluation = evaluateGuess(guess, _targetWord);
    _guesses.add(guess);
    _evaluations.add(evaluation);
    _updateKeyStatuses(guess, evaluation);
    _updateHardModeConstraints(guess, evaluation);

    final won = guess == _targetWord;
    final lost = !won && _guesses.length >= maxGuesses;

    if (won) {
      _status = GameStatus.won;
    } else if (lost) {
      _status = GameStatus.lost;
    }

    if (persist) {
      await _progressService.updateTodayRecord(
        dateKey: _dateKey,
        guesses: _guesses,
        status: _status,
      );

      if (won || lost) {
        _stats = await _progressService.recordResult(
          dateKey: _dateKey,
          won: won,
          guessCount: _guesses.length,
        );
      }
    }
  }

  void _updateKeyStatuses(String guess, List<TileStatus> evaluation) {
    for (var i = 0; i < guess.length; i++) {
      final letter = guess[i];
      final newStatus = evaluation[i];
      final existing = _keyStatuses[letter] ?? TileStatus.unknown;
      if (newStatus.priority > existing.priority) {
        _keyStatuses[letter] = newStatus;
      }
    }
  }

  void _updateHardModeConstraints(String guess, List<TileStatus> evaluation) {
    for (var i = 0; i < guess.length; i++) {
      if (evaluation[i] == TileStatus.correct) {
        _requiredPositions[i] = guess[i];
      } else if (evaluation[i] == TileStatus.present) {
        _requiredLetters.add(guess[i]);
      }
    }
  }
}
