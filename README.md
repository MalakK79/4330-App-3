# Daily Puzzler

A daily puzzle app built with Flutter. The landing page (blue/yellow brand
look) is the app's home; tapping **WORDLE** opens today's word puzzle, with
on-device progress tracking (streak, win %, guess distribution) and an
optional Hard Mode. The structure leaves room to add more daily puzzles
behind the same landing page later.

## Design decisions (from our setup discussion)

- **Word source**: a bundled local word list (`lib/data/word_list.dart`, 500+
  common 5-letter words) — no backend, works fully offline. The word of the
  day is picked deterministically from the calendar date, so everyone on the
  same day gets the same puzzle (same approach as the original Wordle).
- **Progress storage**: on-device only, via `shared_preferences`. No account
  or sync — streak/stats live in that device's local storage.
- **Platforms**: no platform-specific code is used, so this runs on Android,
  iOS, web, and desktop from the same `lib/` — see the gap below though.
- **Hard Mode**: an optional per-puzzle setting (toggle in the settings
  dialog, locked once you've made your first guess) that requires reusing
  revealed hints (green → same position, yellow → included somewhere) in
  later guesses, matching the original Wordle's hard mode.

## Project structure

```
lib/
  main.dart                       # App entry point, theming, provider wiring
  data/
    word_list.dart                 # Bundled 5-letter word list
  models/
    tile_status.dart               # correct / present / absent / unknown
    game_status.dart               # playing / won / lost
    player_stats.dart              # streak, win %, guess distribution
    daily_game_record.dart         # today's in-progress/finished puzzle
  services/
    daily_word_service.dart        # date -> word, date -> puzzle number
    guess_evaluator.dart           # Wordle-rules letter evaluation (handles duplicate letters correctly)
    progress_service.dart          # SharedPreferences persistence
  providers/
    game_provider.dart             # All game state + logic (ChangeNotifier)
  widgets/
    letter_tile.dart               # One grid square
    guess_grid.dart                # The 6x5 grid
    keyboard_widget.dart           # On-screen QWERTY keyboard
    stats_dialog.dart              # Stats popup
    settings_dialog.dart           # Hard Mode toggle
  screens/
    welcome_screen.dart            # Landing page (blue/yellow) with the WORDLE button
    game_screen.dart               # The Wordle game itself; handles physical + on-screen keyboard input
test/
  widget_test.dart                 # Smoke tests
```

## Gameplay notes

- 6 guesses, 5-letter words, same rules as the original Wordle.
- Guess validation is intentionally permissive for this MVP: any 5-letter
  alphabetic guess is accepted rather than checked against a huge separate
  dictionary. If you want stricter "that's not a real word" rejection,
  swap in a larger word list for guess validation vs. the answer pool.
- Progress persists across app restarts: if you close the app mid-puzzle,
  your guesses and keyboard colors are restored; you can't play the same
  day's puzzle twice.
- Physical keyboard input works (for web/desktop) alongside the on-screen
  keyboard.

## Running it

```
flutter pub get
flutter run
```

(If `android/`, `ios/`, `web/`, etc. are ever missing — e.g. after a fresh
clone that didn't include them — regenerate with `flutter create .` from the
project root; it won't touch `lib/`, `pubspec.yaml`, or other existing files.)

## Renaming the installed app label (optional)

The Dart-side app name is already "Daily Puzzler" (window title, browser tab,
Android task switcher). If you also want the name shown under the app icon
on each platform to say "Daily Puzzler", edit these by hand — they live in
the platform folders `flutter create` generates, so they aren't something
this project's Dart code controls:

- **Android**: `android/app/src/main/AndroidManifest.xml` → change the
  `android:label="..."` value.
- **iOS**: `ios/Runner/Info.plist` → set `CFBundleDisplayName` (add the key
  if it isn't there) to `Daily Puzzler`.
- **Windows**: `windows/runner/main.cpp` → change the window title string
  passed to `window.Create(...)`.
- **Web**: `web/index.html` (`<title>`) and `web/manifest.json`
  (`"name"`/`"short_name"`).

## Possible next steps

- Share button (emoji grid summary, like the original Wordle)
- Win/loss animations (tile flip reveal, keyboard shake on invalid guess)
- A larger/second word list specifically for guess validation
- More puzzles on the landing page alongside Wordle
- Cloud sync of stats across devices, if that becomes desirable later
