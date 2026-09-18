import 'package:flutter/material.dart';

import '../models/tile_status.dart';
import '../providers/word_guess_provider.dart';

const List<String> _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
const List<String> _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
const List<String> _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

/// The on-screen QWERTY keyboard. Keys are colored using the same
/// correct/present/absent scheme as the grid tiles, so players can see at a
/// glance which letters they've ruled in or out.
///
/// Takes any [WordGuessProvider], so both guessing games share one keyboard.
class KeyboardWidget extends StatelessWidget {
  const KeyboardWidget({
    super.key,
    required this.provider,
    required this.onKey,
    required this.onEnter,
    required this.onBackspace,
  });

  final WordGuessProvider provider;
  final ValueChanged<String> onKey;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _keyRow(context, _row1),
        const SizedBox(height: 8),
        _keyRow(context, _row2),
        const SizedBox(height: 8),
        _keyRow(
          context,
          _row3,
          leading: _ActionKey(label: 'ENTER', onTap: onEnter, flex: 3),
          trailing: _ActionKey(
            icon: Icons.backspace_outlined,
            onTap: onBackspace,
            flex: 3,
          ),
        ),
      ],
    );
  }

  Widget _keyRow(
    BuildContext context,
    List<String> letters, {
    Widget? leading,
    Widget? trailing,
  }) {
    return Row(
      children: [
        if (leading != null) leading,
        ...letters.map((l) => _LetterKey(
              letter: l,
              status: provider.keyStatuses[l] ?? TileStatus.unknown,
              onTap: () => onKey(l),
            )),
        if (trailing != null) trailing,
      ],
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.status,
    required this.onTap,
  });

  final String letter;
  final TileStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;

    switch (status) {
      case TileStatus.correct:
        background = const Color(0xFF6AAA64);
        foreground = Colors.white;
        break;
      case TileStatus.present:
        background = const Color(0xFFC9B458);
        foreground = Colors.white;
        break;
      case TileStatus.absent:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
        break;
      case TileStatus.unknown:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        break;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    this.label,
    this.icon,
    required this.onTap,
    this.flex = 2,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : Icon(icon, size: 20, color: scheme.onSecondaryContainer),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
