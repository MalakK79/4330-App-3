import 'package:flutter/material.dart';

/// The Synonym game's prompt, sitting above the grid: the synonym the
/// player has to work back from.
///
/// It's the one piece of information the round hands out for free, so it
/// gets a card of its own rather than being tucked into the app bar — and
/// it stays on screen for the whole round, since the player needs it on
/// every guess.
class ClueBanner extends StatelessWidget {
  const ClueBanner({super.key, required this.clue});

  final String clue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Clue: a synonym of $clue',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FIND A WORD MEANING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: scheme.onSecondaryContainer.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            // Long clues ("Enthusiastic") would otherwise wrap or clip on a
            // narrow phone; scaling down keeps the prompt on one line.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                clue.toUpperCase(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
