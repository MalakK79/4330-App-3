import 'package:flutter/material.dart';

/// Shown as soon as a round ends.
///
/// On a loss it reveals the answer, which is the only place the player ever
/// gets to see it. Either way the primary action is the same: deal another
/// random word and keep playing. "Close" just dismisses to the finished
/// board, where [RoundOverBar] still offers the same new-word action.
///
/// Shared by both guessing games. [clue] is the Synonym game's prompt; it's
/// null for Wordle, which has no clue to restate.
class RoundResultDialog extends StatelessWidget {
  const RoundResultDialog({
    super.key,
    required this.won,
    required this.answer,
    required this.guessCount,
    required this.maxGuesses,
    required this.currentStreak,
    required this.bestStreak,
    required this.onNewWord,
    required this.onViewStats,
    this.clue,
  });

  final bool won;
  final String answer;
  final String? clue;
  final int guessCount;
  final int maxGuesses;
  final int currentStreak;
  final int bestStreak;
  final VoidCallback onNewWord;
  final VoidCallback onViewStats;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(won ? 'You got it! 🎉' : 'Out of guesses'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            won
                ? 'Solved in $guessCount/$maxGuesses guesses.'
                : 'You used all $maxGuesses guesses. The word was:',
          ),
          if (!won) ...[
            const SizedBox(height: 12),
            _answerChip(context),
          ],
          if (clue != null) ...[
            const SizedBox(height: 12),
            Text(
              won ? 'Clue: $clue' : '$answer means "$clue".',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            won
                ? 'Streak: $currentStreak in a row'
                : 'Streak reset to 0 — best was $bestStreak.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (won && currentStreak == bestStreak && currentStreak > 1) ...[
            const SizedBox(height: 4),
            const Text('That\'s a new personal best!'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onViewStats();
          },
          child: const Text('Stats'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNewWord();
          },
          child: Text(won ? 'Next Word' : 'New Word'),
        ),
      ],
    );
  }

  Widget _answerChip(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6AAA64),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          answer,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

/// Persistent footer shown above the keyboard once a round is over, so the
/// new-word action is still reachable after the dialog has been dismissed
/// (and so the answer stays on screen after a loss).
class RoundOverBar extends StatelessWidget {
  const RoundOverBar({
    super.key,
    required this.won,
    required this.answer,
    required this.onNewWord,
  });

  final bool won;
  final String answer;
  final VoidCallback onNewWord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              won ? 'Solved! $answer' : 'The word was $answer',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNewWord,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(won ? 'Next Word' : 'New Word'),
          ),
        ],
      ),
    );
  }
}
