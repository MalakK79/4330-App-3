import 'package:flutter/material.dart';

import '../providers/game_provider.dart';

/// Simple settings dialog — currently just the Hard Mode toggle.
///
/// Hard Mode enforces that any hint revealed by a previous guess (a green
/// letter locked to its position, or a yellow letter known to be in the
/// word) must be reused in every subsequent guess — same as the original
/// Wordle's hard mode. It can only be toggled before the first guess of a
/// puzzle is made, exactly like upstream Wordle, so it can't be flipped
/// mid-solve to dodge a constraint.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key, required this.provider});

  final GameProvider provider;

  @override
  Widget build(BuildContext context) {
    final lockedByProgress = provider.guesses.isNotEmpty;

    return AlertDialog(
      title: const Text('Settings'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hard Mode'),
            subtitle: Text(
              lockedByProgress
                  ? 'Locked for the rest of today\'s puzzle'
                  : 'Revealed hints must be used in later guesses',
            ),
            value: provider.hardMode,
            onChanged: lockedByProgress
                ? null
                : (value) {
                    provider.setHardMode(value);
                    setState(() {});
                  },
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
