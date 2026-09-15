# Daily Puzzler

A daily puzzle app built with Flutter. The landing page is the app's 
home; tapping **WORDLE** opens today's word puzzle, with
on-device progress tracking and an optional Hard Mode. The structure
leaves room to add more daily puzzles behind the same landing page later.

## Design decisions 

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


  
