import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scramble_status.dart';
import '../providers/scramble_provider.dart';
import '../widgets/scrambled_letters_row.dart';

/// Screen for the Word Scramble puzzle.
///
/// OUTLINE ONLY: wires up a scrambled word, a guess field, and a win state.
/// No fail-condition UI or scoreboard yet — see [ScrambleProvider].
class ScrambleScreen extends StatefulWidget {
  const ScrambleScreen({super.key});

  @override
  State<ScrambleScreen> createState() => _ScrambleScreenState();
}

class _ScrambleScreenState extends State<ScrambleScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _lastShownError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeShowError(ScrambleProvider provider) {
    final error = provider.errorMessage;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 2),
          ));
        provider.clearError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScrambleProvider>();
    _maybeShowError(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WORD SCRAMBLE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScrambledLettersRow(letters: provider.scrambledWord),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                enabled: provider.canEdit,
                style: const TextStyle(fontSize: 22, letterSpacing: 4),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your guess',
                ),
                onChanged: provider.updateInput,
                onSubmitted: (_) => provider.submitGuess(),
              ),
              const SizedBox(height: 16),
              if (provider.status == ScrambleStatus.won) ...[
                Text(
                  'Solved! ${provider.targetWord}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF6AAA64),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    _controller.clear();
                    provider.newWord();
                  },
                  child: const Text('Next Word'),
                ),
              ] else
                FilledButton(
                  onPressed: provider.submitGuess,
                  child: const Text('Submit'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
