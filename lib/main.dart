import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const DailyPuzzlerApp());
}

class DailyPuzzlerApp extends StatelessWidget {
  const DailyPuzzlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider()..init(),
      child: MaterialApp(
        title: 'Daily Puzzler',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF6AAA64), // Wordle "correct" green
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF6AAA64),
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const WelcomeScreen(),
      ),
    );
  }
}
