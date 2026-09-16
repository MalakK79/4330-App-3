import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_status.dart';
import '../providers/game_provider.dart';
import '../widgets/guess_grid.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/round_result_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/stats_dialog.dart';
import '../widgets/streak_counter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focusNode = FocusNode();
  String? _lastShownError;

  /// The round whose end has already been announced, so the result dialog
  /// pops exactly once per round instead of on every rebuild.
  String? _announcedRound;

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
    if (!provider.isRoundOver) {
      _announcedRound = null;
      return;
    }
    // Keyed by the answer so a new round re-arms the announcement even if
    // two rounds in a row end the same way.
    if (_announcedRound == provider.targetWord) return;
    _announcedRound = provider.targetWord;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResultDialog(provider);
    });
  }

  void _showResultDialog(GameProvider provider) {
    showDialog(
      context: context,
      builder: (_) => RoundResultDialog(
        won: provider.status == GameStatus.won,
        answer: provider.targetWord,
        guessCount: provider.guesses.length,
        maxGuesses: GameProvider.maxGuesses,
        currentStreak: provider.currentStreak,
        bestStreak: provider.bestStreak,
        onNewWord: provider.newGame,
        onViewStats: () => _showStats(provider),
      ),
    );
  }

  void _showStats(GameProvider provider) {
    showDialog(
      context: context,
      builder: (_) => StatsDialog(stats: provider.stats),
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
        title: const Text(
          'WORDLE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => _showStats(provider),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: StreakCounter(
            currentStreak: provider.currentStreak,
            bestStreak: provider.bestStreak,
            roundNumber: provider.roundNumber,
          ),
        ),
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
              if (provider.isRoundOver)
                RoundOverBar(
                  won: provider.status == GameStatus.won,
                  answer: provider.targetWord,
                  onNewWord: provider.newGame,
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
