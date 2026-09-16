# Daily Puzzler

A puzzle app built with Flutter. The landing page is the app's home; tapping
**WORDLE** opens the word game, with on-device progress tracking and an
optional Hard Mode. The landing page has room for the app's two other
puzzles, which aren't built yet.

## Wordle

Guess a hidden 5-letter word in six tries. Each guess colors its tiles:
green = right letter, right spot; yellow = right letter, wrong spot; grey =
not in the word. The on-screen keyboard (and a physical keyboard, on
desktop and web) colors itself to match.

- **Every round is a new random word**, drawn from the bundled list, so the
  game can be played as many times in a row as you like. The same word is
  never dealt twice in a row.
- **Win** and you're offered the next word; **lose** and the answer is
  revealed — in the dialog and on the board — next to a button for a new
  one.
- **Streak** counts words solved in a row. It's shown above the grid, grows
  with every win, and resets to zero on a loss. Your best streak is kept
  alongside it and survives losses. Starting a new word without finishing
  the current one doesn't count as a loss.

## Design decisions

- **Word source**: a bundled local word list (`lib/data/word_list.dart`, 500+
  common 5-letter words) — no backend, works fully offline. Answers are
  drawn from it at random (`lib/services/random_word_service.dart`). Guess
  validation accepts any 5-letter input rather than only listed words, since
  the list is small and rejecting real words is more annoying than allowing
  the odd nonsense guess.
- **Progress storage**: on-device only, via `shared_preferences`. No account
  or sync — streak/stats live in that device's local storage. The round in
  progress is saved too, so quitting mid-word resumes the same puzzle;
  finished rounds aren't resumed, so a relaunch deals a fresh word.
- **Platforms**: no platform-specific code is used, so this runs on Android,
  iOS, web, and desktop from the same `lib/`.
- **Hard Mode**: an optional setting (toggle in the settings dialog, locked
  once you've made your first guess of a round) that requires reusing
  revealed hints (green → same position, yellow → included somewhere) in
  later guesses, matching the original Wordle's hard mode.

## Layout

Code is split by responsibility rather than piled into `main.dart`:

| Path | What lives there |
| --- | --- |
| `lib/main.dart` | App entry, theme, provider wiring |
| `lib/models/` | Plain data: tile/game status, round record, player stats |
| `lib/services/` | Word selection, guess evaluation, on-device storage |
| `lib/providers/` | `GameProvider` — all round state and game rules |
| `lib/screens/` | Landing page and game screen |
| `lib/widgets/` | Grid, tiles, keyboard, streak counter, dialogs |

## Tests

`flutter test` covers the game rules (streak growth and reset, running out
of guesses, new-word behavior, resuming a round) and the screen flows for
winning and losing.
