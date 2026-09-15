import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_game_record.dart';
import '../models/game_status.dart';
import '../models/player_stats.dart';

/// Reads/writes everything that needs to survive an app restart:
/// aggregate stats (streak, win %, guess distribution), the hard-mode
/// setting, and today's in-progress puzzle state.
///
/// Everything is on-device only (via [SharedPreferences]) — no account or
/// network sync. That keeps things simple and private, at the cost of not
/// following the player across devices.
class ProgressService {
  static const _kStats = 'wordle.stats.v1';
  static const _kHardMode = 'wordle.hardMode.v1';
  static const _kTodayRecord = 'wordle.todayRecord.v1';

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

  /// Applies the result of a just-finished game (win or loss) to the
  /// aggregate stats, updating streaks and guess distribution.
  Future<PlayerStats> recordResult({
    required String dateKey,
    required bool won,
    required int guessCount,
  }) async {
    final current = await loadStats();

    final newDistribution = List<int>.from(current.guessDistribution);
    if (won && guessCount >= 1 && guessCount <= newDistribution.length) {
      newDistribution[guessCount - 1] += 1;
    }

    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + (won ? 1 : 0),
      currentStreak: won ? current.currentStreak + 1 : 0,
      maxStreak: won
          ? (current.currentStreak + 1 > current.maxStreak
              ? current.currentStreak + 1
              : current.maxStreak)
          : current.maxStreak,
      guessDistribution: newDistribution,
      lastPlayedDate: dateKey,
      lastWonDate: won ? dateKey : current.lastWonDate,
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

  Future<DailyGameRecord?> loadTodayRecord(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTodayRecord);
    if (raw == null) return null;
    try {
      final record =
          DailyGameRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // A record from a previous day is stale — today's puzzle starts fresh.
      if (record.puzzleDate != dateKey) return null;
      return record;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTodayRecord(DailyGameRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTodayRecord, jsonEncode(record.toJson()));
  }

  /// Convenience used by the provider after every guess.
  Future<void> updateTodayRecord({
    required String dateKey,
    required List<String> guesses,
    required GameStatus status,
  }) {
    return saveTodayRecord(DailyGameRecord(
      puzzleDate: dateKey,
      guesses: guesses,
      status: status,
    ));
  }
}
