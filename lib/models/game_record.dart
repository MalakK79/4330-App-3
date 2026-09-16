import 'game_status.dart';

/// Persisted snapshot of the round in progress, so closing the app mid-word
/// and reopening it resumes the same puzzle instead of silently swapping in
/// a different answer.
///
/// Only unfinished rounds are stored; once a round is won or lost it is
/// cleared, and the next launch deals a fresh word.
class GameRecord {
  GameRecord({
    required this.targetWord,
    required this.guesses,
    required this.status,
  });

  /// The answer for this round, uppercase.
  final String targetWord;

  /// Each submitted guess, in order, as the raw 5-letter word.
  final List<String> guesses;

  final GameStatus status;

  Map<String, dynamic> toJson() => {
        'targetWord': targetWord,
        'guesses': guesses,
        'status': status.name,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      targetWord: json['targetWord'] as String,
      guesses: (json['guesses'] as List).map((e) => e as String).toList(),
      status: GameStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStatus.playing,
      ),
    );
  }
}
