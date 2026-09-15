/// Aggregate player statistics, persisted on-device.
class PlayerStats {
  PlayerStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    List<int>? guessDistribution,
    this.lastPlayedDate,
    this.lastWonDate,
  }) : guessDistribution = guessDistribution ?? List<int>.filled(6, 0);

  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int maxStreak;

  /// Index 0 = number of games won in 1 guess, index 5 = won in 6 guesses.
  final List<int> guessDistribution;

  /// ISO-8601 date string (yyyy-mm-dd) of the last day a game was completed.
  final String? lastPlayedDate;

  /// ISO-8601 date string (yyyy-mm-dd) of the last day a game was won.
  final String? lastWonDate;

  double get winPercent =>
      gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed) * 100;

  PlayerStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? maxStreak,
    List<int>? guessDistribution,
    String? lastPlayedDate,
    String? lastWonDate,
  }) {
    return PlayerStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      guessDistribution: guessDistribution ?? this.guessDistribution,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      lastWonDate: lastWonDate ?? this.lastWonDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'guessDistribution': guessDistribution,
        'lastPlayedDate': lastPlayedDate,
        'lastWonDate': lastWonDate,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      guessDistribution: (json['guessDistribution'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          List<int>.filled(6, 0),
      lastPlayedDate: json['lastPlayedDate'] as String?,
      lastWonDate: json['lastWonDate'] as String?,
    );
  }
}
