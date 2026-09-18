import 'package:flutter/foundation.dart';

import '../models/game_status.dart';
import '../models/player_stats.dart';
import '../models/tile_status.dart';
import '../services/guess_evaluator.dart';
import '../services/progress_service.dart';

/// The shared rules engine behind every Wordle-style game in the app: six
/// guesses at a hidden 5-letter word, green/yellow/grey tile evaluation,
/// on-screen keyboard coloring, optional hard mode, and a persisted
/// streak/stats record.
///
/// Subclasses supply only what actually differs between games — where the
/// answer comes from, what counts as a submittable guess, and any extra
/// per-round state (the Synonym game's clue, for instance). Everything the
/// UI touches (`addLetter`, `removeLetter`, `submitGuess`, `newGame`, and
/// the read-only getters) lives here, so the grid, keyboard, and dialogs
/// are written once and shared by both games.
///
/// Rounds are endless: [newGame] deals a fresh answer whenever the player
/// wants one, which is what the post-win and post-loss buttons call.
abstract class WordGuessProvider extends ChangeNotifier {
  WordGuessProvider({ProgressService? progressService})
      : progressService = progressService ?? ProgressService();

  static const int wordLength = 5;
  static const int maxGuesses = 6;

  @protected
  final ProgressService progressService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _targetWord = '';

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

  List<String> get guesses => List.unmodifiable(_guesses);
  List<List<TileStatus>> get evaluations => List.unmodifiable(_evaluations);
  String get currentInput => _currentInput;
  GameStatus get status => _status;
  bool get hardMode => _hardMode;
  PlayerStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  Map<String, TileStatus> get keyStatuses => Map.unmodifiable(_keyStatuses);

  /// The answer for the current round. Revealed to the player once the round
  /// is over — on a loss, that reveal is the whole point.
  String get targetWord => _targetWord;

  /// Words solved in a row — the score counter shown on the game screen.
  int get currentStreak => _stats.currentStreak;
  int get bestStreak => _stats.maxStreak;

  /// 1-based number of the round being played, counting every finished round.
  int get roundNumber => _stats.gamesPlayed + 1;

  bool get canEdit => _status == GameStatus.playing;
  bool get isRoundOver => _status != GameStatus.playing;
  int get remainingGuesses => maxGuesses - _guesses.length;

  // --- Hooks for subclasses ------------------------------------------------

  /// Picks the answer for the next round. [avoid] is the word just played,
  /// which implementations shouldn't deal twice in a row.
  @protected
  String drawTarget({String? avoid});

  /// Why [guess] can't be submitted, or null if it's fine. Only called for
  /// input that is already the right length.
  @protected
  String? validationError(String guess) => null;

  /// Extra per-round setup for the answer [word], run as the board is
  /// cleared — e.g. looking up the clue that goes with it.
  @protected
  void onRoundStarted(String word) {}

  /// Whether a saved, unfinished round for [word] can still be resumed.
  /// Games whose answers carry extra data (a clue, say) use this to reject
  /// a stored word that no longer has any.
  @protected
  bool canResume(String word) => true;

  // --- Lifecycle -----------------------------------------------------------

  Future<void> init() async {
    _hardMode = await progressService.getHardMode();
    _stats = await progressService.loadStats();

    // Resume an unfinished round if there is one, so quitting mid-word
    // doesn't quietly swap the answer out from under the player.
    final saved = await progressService.loadCurrentGame();
    if (saved != null && canResume(saved.targetWord)) {
      _startRound(saved.targetWord);
      for (final guess in saved.guesses) {
        await _applyGuess(guess, persist: false);
      }
    } else {
      _startRound(drawTarget());
      await _persistRound();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Abandons whatever is on the board and deals a brand-new answer.
  ///
  /// This backs the "New Word" button shown after a win or a loss. A round
  /// abandoned while still playable isn't counted as a loss, so it leaves
  /// the streak alone.
  Future<void> newGame() async {
    _startRound(drawTarget(avoid: _targetWord));
    notifyListeners();
    await _persistRound();
  }

  /// Resets the board for [word], clearing everything from the last round.
  void _startRound(String word) {
    final upper = word.toUpperCase();
    onRoundStarted(upper);
    _targetWord = upper;
    _guesses.clear();
    _evaluations.clear();
    _keyStatuses.clear();
    _requiredPositions.clear();
    _requiredLetters.clear();
    _currentInput = '';
    _status = GameStatus.playing;
    _errorMessage = null;
  }

  Future<void> _persistRound() {
    return progressService.saveCurrentGame(
      targetWord: _targetWord,
      guesses: _guesses,
      status: _status,
    );
  }

  // --- Player input --------------------------------------------------------

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
    await progressService.setHardMode(value);
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

    final invalid = validationError(_currentInput);
    if (invalid != null) {
      _errorMessage = invalid;
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

    if (!persist) return;

    if (won || lost) {
      // The round is over: there's nothing left to resume, and it now counts
      // toward the streak.
      await progressService.clearCurrentGame();
      _stats = await progressService.recordResult(
        won: won,
        guessCount: _guesses.length,
      );
    } else {
      await _persistRound();
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
