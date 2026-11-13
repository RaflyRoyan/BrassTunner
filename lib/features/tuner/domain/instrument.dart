import '../../../core/pitch/note_mapper.dart';

/// Key an instrument is pitched in, i.e. which concert note sounds when the
/// player reads a written C.
enum InstrumentKey {
  bFlat('B♭'),
  f('F'),
  eFlat('E♭'),
  concert('C');

  const InstrumentKey(this.label);
  final String label;
}

/// Brass instruments with their transposition.
///
/// [writtenOffset] is the number of semitones from sounding (concert) pitch
/// up to the written note the player reads.
enum Instrument {
  trumpet(InstrumentKey.bFlat, 2),
  flugelhorn(InstrumentKey.bFlat, 2),
  // Treble-clef baritone reads like a B♭ trumpet one octave lower.
  baritoneTrebleClef(InstrumentKey.bFlat, 14),
  mellophone(InstrumentKey.f, 7),
  frenchHorn(InstrumentKey.f, 7),
  altoHorn(InstrumentKey.eFlat, 9),
  trombone(InstrumentKey.concert, 0),
  euphoniumBassClef(InstrumentKey.concert, 0),
  tuba(InstrumentKey.concert, 0);

  const Instrument(this.key, this.writtenOffset);

  final InstrumentKey key;
  final int writtenOffset;

  bool get isTransposing => writtenOffset != 0;

  /// The note the player reads for a sounding [concert] note.
  Note writtenNote(Note concert) => concert.transpose(writtenOffset);
}
