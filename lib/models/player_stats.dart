/// Aggregate player statistics, persisted on-device.
///
/// [currentStreak] is the headline number the game screen shows: how many
/// words have been solved in a row. It grows with every win and resets to
/// zero the moment a round is lost.
class PlayerStats {
  PlayerStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    List<int>? guessDistribution,
  }) : guessDistribution = guessDistribution ?? List<int>.filled(6, 0);

  final int gamesPlayed;
  final int gamesWon;

  /// Words solved in a row, without a loss in between.
  final int currentStreak;

  /// The best [currentStreak] ever reached.
  final int maxStreak;

  /// Index 0 = number of games won in 1 guess, index 5 = won in 6 guesses.
  final List<int> guessDistribution;

  double get winPercent =>
      gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed) * 100;

  PlayerStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? maxStreak,
    List<int>? guessDistribution,
  }) {
    return PlayerStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      guessDistribution: guessDistribution ?? this.guessDistribution,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'guessDistribution': guessDistribution,
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
    );
  }
}
