import 'package:flutter/material.dart';

/// Displays each letter of the scrambled word as its own tile, matching
/// the visual language of [LetterTile] in the Wordle game but without any
/// correctness coloring — these are just the shuffled letters to unscramble.
class ScrambledLettersRow extends StatelessWidget {
  const ScrambledLettersRow({super.key, required this.letters});

  final String letters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      children: letters.split('').map((letter) {
        return Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scheme.onSecondaryContainer,
            ),
          ),
        );
      }).toList(),
    );
  }
}
