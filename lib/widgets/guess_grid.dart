import 'package:flutter/material.dart';

import '../models/tile_status.dart';
import '../providers/game_provider.dart';
import 'letter_tile.dart';

/// Renders the full 6-row guess grid: completed guesses (colored), the
/// row currently being typed (outlined only), and empty rows beyond that.
class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key, required this.provider});

  final GameProvider provider;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var r = 0; r < GameProvider.maxGuesses; r++) {
      if (r < provider.guesses.length) {
        rows.add(_row(provider.guesses[r], provider.evaluations[r]));
      } else if (r == provider.guesses.length && provider.canEdit) {
        rows.add(_currentRow(provider.currentInput));
      } else {
        rows.add(_row(null, null));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _row(String? guess, List<TileStatus>? evaluation) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(GameProvider.wordLength, (i) {
        final letter = guess != null ? guess[i] : '';
        final status = evaluation != null ? evaluation[i] : TileStatus.unknown;
        return LetterTile(letter: letter, status: status);
      }),
    );
  }

  Widget _currentRow(String input) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(GameProvider.wordLength, (i) {
        final letter = i < input.length ? input[i] : '';
        return LetterTile(letter: letter, status: TileStatus.unknown);
      }),
    );
  }
}
