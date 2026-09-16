import 'package:flutter/material.dart';

/// The score readout for the Wordle game: how many words have been solved
/// in a row, alongside the best streak reached so far and the current round
/// number.
///
/// The streak is the headline number, so it gets the filled pill; "best" and
/// "round" sit next to it as quieter context.
class StreakCounter extends StatelessWidget {
  const StreakCounter({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.roundNumber,
  });

  final int currentStreak;
  final int bestStreak;
  final int roundNumber;

  static const _green = Color(0xFF6AAA64);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      // On narrow phones the three stats don't fit at full size; shrinking
      // them keeps the whole row readable instead of clipping "ROUND".
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pill(),
            const SizedBox(width: 10),
            _quietStat(context, 'BEST', '$bestStreak'),
            const SizedBox(width: 10),
            _quietStat(context, 'ROUND', '$roundNumber'),
          ],
        ),
      ),
    );
  }

  Widget _pill() {
    return Semantics(
      label: 'Current streak: $currentStreak solved in a row',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: currentStreak > 0 ? _green : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'STREAK $currentStreak',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quietStat(BuildContext context, String label, String value) {
    final color = Theme.of(context).textTheme.bodySmall?.color;
    return Text(
      '$label $value',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }
}
