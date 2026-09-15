import 'package:flutter/material.dart';

import '../models/player_stats.dart';

/// A lightweight dialog summarizing progress: streaks, win rate, and the
/// guess distribution. Deliberately simple — no share/export, that can be
/// layered on later if wanted.
class StatsDialog extends StatelessWidget {
  const StatsDialog({super.key, required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.guessDistribution.isEmpty
        ? 1
        : stats.guessDistribution.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return AlertDialog(
      title: const Text('Statistics'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('${stats.gamesPlayed}', 'Played'),
                _stat('${stats.winPercent.round()}', 'Win %'),
                _stat('${stats.currentStreak}', 'Streak'),
                _stat('${stats.maxStreak}', 'Max Streak'),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Guess Distribution',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < stats.guessDistribution.length; i++)
              _distributionBar(
                context,
                label: '${i + 1}',
                count: stats.guessDistribution[i],
                maxCount: maxCount,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _distributionBar(
    BuildContext context, {
    required String label,
    required int count,
    required int maxCount,
  }) {
    final fraction = count == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 12, child: Text(label)),
          const SizedBox(width: 6),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.04, 1.0),
              child: Container(
                height: 18,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6AAA64),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
