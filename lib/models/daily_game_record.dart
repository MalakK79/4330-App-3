import 'game_status.dart';

/// Persisted snapshot of *today's* puzzle, so closing and reopening the app
/// resumes exactly where the player left off instead of losing progress or
/// (worse) letting them play the same day twice.
class DailyGameRecord {
  DailyGameRecord({
    required this.puzzleDate,
    required this.guesses,
    required this.status,
  });

  /// ISO-8601 date string (yyyy-mm-dd) this record belongs to.
  final String puzzleDate;

  /// Each submitted guess, in order, as the raw 5-letter word.
  final List<String> guesses;

  final GameStatus status;

  Map<String, dynamic> toJson() => {
        'puzzleDate': puzzleDate,
        'guesses': guesses,
        'status': status.name,
      };

  factory DailyGameRecord.fromJson(Map<String, dynamic> json) {
    return DailyGameRecord(
      puzzleDate: json['puzzleDate'] as String,
      guesses: (json['guesses'] as List).map((e) => e as String).toList(),
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.playing,
      ),
    );
  }
}
