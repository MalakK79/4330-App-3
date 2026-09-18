import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';
import '../models/game_status.dart';
import '../models/player_stats.dart';

/// Reads/writes everything that needs to survive an app restart: aggregate
/// stats (streak, win %, guess distribution), the hard-mode setting, and the
/// round currently in progress.
///
/// Everything is on-device only (via [SharedPreferences]) — no account or
/// network sync. That keeps things simple and private, at the cost of not
/// following the player across devices.
///
/// Each guessing game gets its own [namespace], so Wordle and Synonym keep
/// separate streaks, stats, and saved rounds in the same storage.
class ProgressService {
  ProgressService({this.namespace = 'wordle'});

  /// Prefix for every key this instance touches. Defaults to Wordle's, so
  /// progress saved before the app had a second guessing game still loads.
  final String namespace;

  // v2 keys: v1 stored a date-keyed "puzzle of the day" record and stats
  // with last-played/last-won dates, which no longer apply now that rounds
  // are drawn at random and replayable. Old v1 values are simply ignored.
  String get _kStats => '$namespace.stats.v2';
  String get _kHardMode => '$namespace.hardMode.v1';
  String get _kCurrentGame => '$namespace.currentGame.v2';

  Future<PlayerStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStats);
    if (raw == null) return PlayerStats();
    try {
      return PlayerStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerStats();
    }
  }

  Future<void> saveStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStats, jsonEncode(stats.toJson()));
  }

  /// Applies the result of a just-finished round to the aggregate stats.
  ///
  /// A win extends the streak (and the best streak with it); a loss ends it.
  Future<PlayerStats> recordResult({
    required bool won,
    required int guessCount,
  }) async {
    final current = await loadStats();

    final newDistribution = List<int>.from(current.guessDistribution);
    if (won && guessCount >= 1 && guessCount <= newDistribution.length) {
      newDistribution[guessCount - 1] += 1;
    }

    final newStreak = won ? current.currentStreak + 1 : 0;

    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + (won ? 1 : 0),
      currentStreak: newStreak,
      maxStreak: newStreak > current.maxStreak ? newStreak : current.maxStreak,
      guessDistribution: newDistribution,
    );

    await saveStats(updated);
    return updated;
  }

  Future<bool> getHardMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHardMode) ?? false;
  }

  Future<void> setHardMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHardMode, value);
  }

  /// The unfinished round to resume, or null if there isn't one.
  Future<GameRecord?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCurrentGame);
    if (raw == null) return null;
    try {
      final record =
          GameRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // Finished rounds aren't resumed — the next launch gets a new word.
      if (record.status != GameStatus.playing) return null;
      if (record.targetWord.length != 5) return null;
      return record;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentGame({
    required String targetWord,
    required List<String> guesses,
    required GameStatus status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCurrentGame,
      jsonEncode(GameRecord(
        targetWord: targetWord,
        guesses: guesses,
        status: status,
      ).toJson()),
    );
  }

  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentGame);
  }
}
