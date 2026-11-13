import 'dart:math' as math;

/// How black-key notes are spelled. Brass music is mostly written in flat
/// keys, so flats are the default.
enum Accidental { flat, sharp }

/// A note of the equal-tempered scale, identified by its MIDI number
/// (A4 = 69, C4 = 60).
class Note {
  const Note(this.midi, {this.accidental = Accidental.flat});

  static const _flatNames = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B', //
  ];
  static const _sharpNames = [
    'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B', //
  ];

  final int midi;
  final Accidental accidental;

  /// 0 = C … 11 = B.
  int get pitchClass => midi % 12;

  /// Scientific pitch octave: C4 is middle C.
  int get octave => (midi ~/ 12) - 1;

  /// Note name without octave, e.g. `B♭`.
  String get name =>
      (accidental == Accidental.flat ? _flatNames : _sharpNames)[pitchClass];

  /// Note name with octave, e.g. `B♭3`.
  String get label => '$name$octave';

  /// This note shifted by [semitones] (e.g. for transposing instruments).
  Note transpose(int semitones) =>
      Note(midi + semitones, accidental: accidental);

  @override
  bool operator ==(Object other) => other is Note && other.midi == midi;

  @override
  int get hashCode => midi.hashCode;

  @override
  String toString() => label;
}

/// A frequency resolved to its nearest note and the deviation from it.
class NoteReading {
  const NoteReading({
    required this.note,
    required this.cents,
    required this.frequency,
  });

  final Note note;

  /// Deviation from [note] in cents, in -50..50. Positive means sharp.
  final double cents;

  /// The measured frequency in Hz.
  final double frequency;

  @override
  String toString() =>
      '$note ${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)}¢ '
      '(${frequency.toStringAsFixed(2)} Hz)';
}

/// Converts between frequency and notes for a given A4 reference.
class NoteMapper {
  NoteMapper({this.a4 = 440, this.accidental = Accidental.flat}) {
    if (a4 < minA4 || a4 > maxA4) {
      throw RangeError.range(a4.round(), minA4.round(), maxA4.round(), 'a4');
    }
  }

  static const double minA4 = 430;
  static const double maxA4 = 450;

  /// Reference frequency of A4 in Hz.
  final double a4;
  final Accidental accidental;

  NoteMapper copyWith({double? a4, Accidental? accidental}) =>
      NoteMapper(a4: a4 ?? this.a4, accidental: accidental ?? this.accidental);

  /// Fractional MIDI number of [frequency] (69.0 = A4 exactly).
  double midiOf(double frequency) => 69 + 12 * _log2(frequency / a4);

  NoteReading fromFrequency(double frequency) {
    if (!(frequency > 0) || !frequency.isFinite) {
      throw ArgumentError.value(frequency, 'frequency', 'must be > 0');
    }
    final midiFloat = midiOf(frequency);
    final nearest = midiFloat.round();
    return NoteReading(
      note: Note(nearest, accidental: accidental),
      cents: (midiFloat - nearest) * 100,
      frequency: frequency,
    );
  }

  /// Exact equal-tempered frequency of [note].
  double frequencyOf(Note note) => a4 * math.pow(2, (note.midi - 69) / 12);

  static double _log2(double x) => math.log(x) / math.ln2;
}
