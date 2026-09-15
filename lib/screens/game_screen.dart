import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_status.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/stats_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focusNode = FocusNode();
  String? _lastShownError;
  GameStatus? _lastAnnouncedStatus;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final provider = context.read<GameProvider>();

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      provider.submitGuess();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      provider.removeLetter();
      return KeyEventResult.handled;
    }
    final label = key.keyLabel;
    if (label.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(label)) {
      provider.addLetter(label.toUpperCase());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _maybeShowError(GameProvider provider) {
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

  void _maybeAnnounceResult(GameProvider provider) {
    if (provider.status == GameStatus.playing) {
      _lastAnnouncedStatus = null;
      return;
    }
    if (_lastAnnouncedStatus == provider.status) return;
    _lastAnnouncedStatus = provider.status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResultDialog(provider);
    });
  }

  void _showResultDialog(GameProvider provider) {
    final won = provider.status == GameStatus.won;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(won ? 'You got it! 🎉' : 'So close!'),
        content: Text(
          won
              ? 'Solved in ${provider.guesses.length}/${GameProvider.maxGuesses} guesses.'
              : 'The word was ${provider.targetWord}. Come back tomorrow for a new puzzle!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => StatsDialog(stats: provider.stats),
              );
            },
            child: const Text('View Stats'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _maybeShowError(provider);
    _maybeAnnounceResult(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WORDLE #${provider.puzzleNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => StatsDialog(stats: provider.stats),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => SettingsDialog(provider: provider),
            ),
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: GuessGrid(provider: provider),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: KeyboardWidget(
                  provider: provider,
                  onKey: provider.addLetter,
                  onEnter: provider.submitGuess,
                  onBackspace: provider.removeLetter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
