/// One entry in the Synonym game's word bank: a hidden 5-letter [word] and
/// the [clue] — a synonym of it — that the player sees instead.
///
/// The clue is the only thing shown until the round ends, so it has to point
/// at the answer on its own; the grid's green/yellow/grey feedback does the
/// rest of the narrowing.
class SynonymPuzzle {
  const SynonymPuzzle(this.word, this.clue);

  /// The answer, uppercase and exactly 5 letters so it fits the same grid
  /// the Wordle game uses.
  final String word;

  /// A one-word synonym of [word], shown to the player as the prompt.
  final String clue;
}
