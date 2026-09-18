import '../services/progress_service.dart';
import '../services/synonym_service.dart';
import 'word_guess_provider.dart';

/// Drives a round of the Synonym game: same six-guess board, tile coloring,
/// and streak as Wordle, but the player starts from a [clue] — a synonym of
/// the hidden word — instead of from nothing.
///
/// All the shared rules live in [WordGuessProvider]; this only picks the
/// answer, remembers the clue that goes with it, and keeps its progress in
/// its own storage namespace so the Synonym streak is tracked separately
/// from the Wordle one.
class SynonymProvider extends WordGuessProvider {
  SynonymProvider({
    SynonymService? synonymService,
    ProgressService? progressService,
  })  : _synonymService = synonymService ?? SynonymService(),
        super(
          progressService:
              progressService ?? ProgressService(namespace: 'synonym'),
        );

  // Re-exported so `SynonymProvider.wordLength` keeps working at call sites;
  // static members aren't inherited in Dart.
  static const int wordLength = WordGuessProvider.wordLength;
  static const int maxGuesses = WordGuessProvider.maxGuesses;

  final SynonymService _synonymService;

  String _clue = '';

  /// The synonym shown to the player — the whole prompt for the round.
  String get clue => _clue;

  @override
  String drawTarget({String? avoid}) {
    final puzzle = _synonymService.nextPuzzle(avoid: avoid);
    _clue = puzzle.clue;
    return puzzle.word;
  }

  @override
  void onRoundStarted(String word) {
    // Covers the resume path, where the base class starts a round from a
    // stored word rather than from [drawTarget] — the clue has to be looked
    // up again. [canResume] has already established there is one.
    _clue = _synonymService.puzzleFor(word)?.clue ?? _clue;
  }

  /// A stored round is only resumable while its word still has a clue; if
  /// the word bank changed under it, the player gets a fresh puzzle instead
  /// of a board with no prompt.
  @override
  bool canResume(String word) => _synonymService.puzzleFor(word) != null;

  @override
  String? validationError(String guess) {
    return _synonymService.isValidGuess(guess) ? null : 'Not a valid word';
  }
}
