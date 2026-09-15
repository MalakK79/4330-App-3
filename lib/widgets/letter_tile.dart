import 'package:flutter/material.dart';

import '../models/tile_status.dart';

/// A single letter square in the guess grid.
class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.letter,
    required this.status,
  });

  final String letter;
  final TileStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(context, status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      margin: const EdgeInsets.all(3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
        ),
      ),
    );
  }

  _TileColors _colorsFor(BuildContext context, TileStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case TileStatus.correct:
        return _TileColors(
          background: const Color(0xFF6AAA64),
          border: const Color(0xFF6AAA64),
          foreground: Colors.white,
        );
      case TileStatus.present:
        return _TileColors(
          background: const Color(0xFFC9B458),
          border: const Color(0xFFC9B458),
          foreground: Colors.white,
        );
      case TileStatus.absent:
        return _TileColors(
          background: scheme.surfaceContainerHighest,
          border: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        );
      case TileStatus.unknown:
        return _TileColors(
          background: Colors.transparent,
          border: letter.isEmpty ? scheme.outlineVariant : scheme.outline,
          foreground: scheme.onSurface,
        );
    }
  }
}

class _TileColors {
  _TileColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
