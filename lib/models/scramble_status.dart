/// Overall status of a Word Scramble round.
///
/// Deliberately just two states for now — [ScrambleStatus.lost] will be
/// added once fail conditions (e.g. a limited number of attempts) are
/// defined.
enum ScrambleStatus {
  playing,
  won,
}
