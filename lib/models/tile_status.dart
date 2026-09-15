/// The evaluation state of a single letter tile (or keyboard key).
enum TileStatus {
  /// Not yet guessed / no info.
  unknown,

  /// Letter isn't in the word at all.
  absent,

  /// Letter is in the word, but in a different position.
  present,

  /// Letter is in the word, in this exact position.
  correct,
}

extension TileStatusPriority on TileStatus {
  /// Higher number = "better" status. Used so a keyboard key never
  /// downgrades (e.g. a key already shown correct on one guess should stay
  /// correct even if a later guess reveals the same letter as "present"
  /// elsewhere).
  int get priority {
    switch (this) {
      case TileStatus.unknown:
        return 0;
      case TileStatus.absent:
        return 1;
      case TileStatus.present:
        return 2;
      case TileStatus.correct:
        return 3;
    }
  }
}
