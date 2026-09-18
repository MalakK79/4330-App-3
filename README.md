# Daily Puzzler

A puzzle app built with Flutter. The landing page is the app's home; tapping
**WORDLE** or **SYNONYM** opens a word game, each with on-device progress
tracking and an optional Hard Mode. The third slot, **WORD SCRAMBLE**, is
still an outline.

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

## Synonym

Same board, different starting point: you're shown a **synonym** of the
hidden 5-letter word ("FIND A WORD MEANING — FURIOUS") and have six tries to
name the word itself (`ANGRY`). Tiles, keyboard coloring, Hard Mode, the
streak counter, the stats dialog, and the win/loss flow all behave exactly
as they do in Wordle, so there's nothing new to learn.

- **The clue stays on screen** for the whole round — it's needed on every
  guess, so it sits above the grid rather than in a dismissable popup.
- **Lose and you're told both halves**: the word and what it meant.
- **Its streak is its own.** Wordle and Synonym keep separate streaks,
  stats, and saved rounds, so playing one never resets the other.

## Design decisions

- **Word source**: a bundled local word list (`lib/data/word_list.dart`, 500+
  common 5-letter words) — no backend, works fully offline. Answers are
  drawn from it at random (`lib/services/random_word_service.dart`). Guess
  validation accepts any 5-letter input rather than only listed words, since
  the list is small and rejecting real words is more annoying than allowing
  the odd nonsense guess.
- **Synonym word bank**: its own bundled list
  (`lib/data/synonym_list.dart`, 230+ answer/clue pairs) rather than the
  Wordle list, because every answer needs a clue attached to it. Clues are
  single words, and answers are all 5 letters so both games share one grid.
- **One rules engine, two games**: `WordGuessProvider` holds everything the
  two guessing games have in common — the six-guess board, tile evaluation,
  keyboard coloring, Hard Mode, and the persisted streak. `GameProvider` and
  `SynonymProvider` subclass it and supply only what differs (where the
  answer comes from, and Synonym's clue). The grid, keyboard, dialogs, and
  streak counter are written once against the base class.
- **Progress storage**: on-device only, via `shared_preferences`. No account
  or sync — streak/stats live in that device's local storage. The round in
  progress is saved too, so quitting mid-word resumes the same puzzle;
  finished rounds aren't resumed, so a relaunch deals a fresh word. Each
  game namespaces its own keys (`wordle.*`, `synonym.*`).
- **Platforms**: no platform-specific code is used, so this runs on Android,
  iOS, web, and desktop from the same `lib/`.
- **Hard Mode**: an optional setting (toggle in the settings dialog, locked
  once you've made your first guess of a round) that requires reusing
  revealed hints (green → same position, yellow → included somewhere) in
  later guesses, matching the original Wordle's hard mode. Both guessing
  games offer it, each remembering its own setting.

## Layout

Code is split by responsibility rather than piled into `main.dart`:

| Path | What lives there |
| --- | --- |
| `lib/main.dart` | App entry, theme, provider wiring |
| `lib/models/` | Plain data: tile/game status, round record, player stats, synonym puzzle |
| `lib/data/` | The bundled word list and synonym word bank |
| `lib/services/` | Word/puzzle selection, guess evaluation, on-device storage |
| `lib/providers/` | `WordGuessProvider` (shared rules) and the per-game subclasses |
| `lib/screens/` | Landing page and one screen per game |
| `lib/widgets/` | Grid, tiles, keyboard, clue banner, streak counter, dialogs |

## Tests

`flutter test` covers the rules of both guessing games (streak growth and
reset, running out of guesses, new-word behavior, resuming a round, and that
the two games' streaks stay independent), the synonym word bank's shape, and
the screen flows for winning and losing.
