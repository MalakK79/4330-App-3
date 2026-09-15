import '../models/tile_status.dart';

/// Evaluates a single guess against the target word using standard Wordle
/// rules, including correct handling of repeated letters: a letter is only
/// marked "present" as many times as it actually appears (unmatched) in the
/// target.
///
/// Example: target=SPEED, guess=ERASE ->
///   E: present (SPEED has an E, not at this position)
///   R: absent
///   A: absent
///   S: present
///   E: absent (the only other E in SPEED was already claimed by index 0)
List<TileStatus> evaluateGuess(String guess, String target) {
  assert(guess.length == target.length);
  final length = guess.length;
  final result = List<TileStatus>.filled(length, TileStatus.absent);

  // Remaining (unmatched) letter counts in the target, for the "present"
  // pass below.
  final remaining = <String, int>{};

  // Pass 1: exact position matches.
  for (var i = 0; i < length; i++) {
    if (guess[i] == target[i]) {
      result[i] = TileStatus.correct;
    } else {
      remaining[target[i]] = (remaining[target[i]] ?? 0) + 1;
    }
  }

  // Pass 2: right letter, wrong position — limited by how many of that
  // letter are still unmatched in the target.
  for (var i = 0; i < length; i++) {
    if (result[i] == TileStatus.correct) continue;
    final letter = guess[i];
    final count = remaining[letter] ?? 0;
    if (count > 0) {
      result[i] = TileStatus.present;
      remaining[letter] = count - 1;
    } else {
      result[i] = TileStatus.absent;
    }
  }

  return result;
}
