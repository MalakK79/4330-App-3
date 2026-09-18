import '../services/progress_service.dart';
import '../services/random_word_service.dart';
import 'word_guess_provider.dart';

/// Drives a round of Wordle.
///
/// All the shared guessing rules — the six-guess board, tile evaluation,
/// keyboard coloring, hard mode, and the persisted streak/stats — live in
/// [WordGuessProvider]. Wordle only has to say where its answers come from
/// and what counts as a submittable guess; the Synonym game subclasses the
/// same base with its own answers on top.
class GameProvider extends WordGuessProvider {
  GameProvider({
    RandomWordService? wordService,
    ProgressService? progressService,
  })  : _wordService = wordService ?? RandomWordService(),
        super(progressService: progressService ?? ProgressService());

  // Re-exported so `GameProvider.wordLength` keeps working at call sites;
  // static members aren't inherited in Dart.
  static const int wordLength = WordGuessProvider.wordLength;
  static const int maxGuesses = WordGuessProvider.maxGuesses;

  final RandomWordService _wordService;

  @override
  String drawTarget({String? avoid}) => _wordService.nextWord(avoid: avoid);

  @override
  String? validationError(String guess) {
    return _wordService.isValidGuess(guess) ? null : 'Not a valid word';
  }
}
