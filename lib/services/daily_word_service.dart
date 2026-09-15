import '../data/word_list.dart';

/// Picks "today's word" deterministically from the date, the same way the
/// original Wordle does: every player on the same calendar day gets the
/// same puzzle, and the puzzle number increments once per day forever
/// (wrapping back through the word list once it's exhausted).
class DailyWordService {
  DailyWordService({List<String>? words}) : _words = words ?? kWordList;

  final List<String> _words;

  /// A fixed reference date. Puzzle #1 falls on this date.
  static final DateTime _epoch = DateTime.utc(2024, 1, 1);

  /// Number of whole days between [_epoch] and [date] (local calendar day,
  /// not affected by time-of-day or timezone offsets within the day).
  int _daysSinceEpoch(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return normalized.difference(_epoch).inDays;
  }

  /// 1-based puzzle number for [date], e.g. "Wordle #123".
  int puzzleNumberForDate(DateTime date) => _daysSinceEpoch(date) + 1;

  /// The answer word for [date], uppercase.
  String wordForDate(DateTime date) {
    final dayIndex = _daysSinceEpoch(date);
    final wrapped = dayIndex % _words.length;
    // dayIndex can be negative for dates before the epoch; keep it positive.
    final safeIndex = wrapped < 0 ? wrapped + _words.length : wrapped;
    return _words[safeIndex];
  }

  /// Canonical yyyy-mm-dd key for [date], used for storage/comparison.
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool isValidGuess(String guess) {
    final upper = guess.toUpperCase();
    if (upper.length != 5) return false;
    // MVP dictionary check: accept any word from the bundled list, plus
    // (to avoid frustrating false rejections) any purely-alphabetic 5-letter
    // input. Swap in a larger dictionary here later for stricter validation.
    return RegExp(r'^[A-Z]{5}$').hasMatch(upper);
  }
}
