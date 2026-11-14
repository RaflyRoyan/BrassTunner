import 'dart:math' as math;

import '../../../core/pitch/note_mapper.dart';
import '../../tuner/domain/instrument.dart';

/// How an instrument lengthens its tubing to reach notes between partials.
enum FingeringSystem {
  /// Three piston valves (trumpet, flugelhorn, baritone, mellophone, alto horn).
  threeValves,

  /// Four valves, the 4th lowering a fourth (euphonium, tuba).
  fourValves,

  /// Single horn in F with three rotary valves.
  fHorn,

  /// Trombone slide, positions 1–7.
  slide,
}

/// A valve combination or a slide position.
class Fingering {
  /// [valves] must be ascending; empty means open.
  const Fingering.valves(this.valves) : position = null;

  const Fingering.slide(int this.position) : valves = const [];

  /// Semitones each valve lowers the open pitch.
  static const valveSemitones = {1: 2, 2: 1, 3: 3, 4: 5};

  final List<int> valves;

  /// Slide position 1–7, or null for valved instruments.
  final int? position;

  bool get isSlide => position != null;
  bool get isOpen => !isSlide && valves.isEmpty;

  /// Semitones below the open (or 1st position) note.
  int get lowering => isSlide
      ? position! - 1
      : valves.fold(0, (sum, v) => sum + valveSemitones[v]!);

  bool uses(int valve) => valves.contains(valve);

  /// Theoretical pitch error of this valve combination in cents, positive
  /// is sharp.
  ///
  /// Each valve slide is cut for its own interval from the open horn, so
  /// combined valves add too little tubing: 1-3 is about 30¢ sharp, 1-2-3
  /// about 54¢. Real instruments compensate partly (3rd slide cut long, main
  /// tuning), so treat this as a tendency, not a measurement. Slide
  /// positions have no such error.
  double get comboCents {
    if (isSlide || valves.length < 2) return 0;
    final added = valves.fold(
      0.0,
      (sum, v) => sum + math.pow(2, valveSemitones[v]! / 12) - 1,
    );
    final needed = math.pow(2, lowering / 12);
    return 1200 * _log2(needed / (1 + added));
  }

  /// e.g. `0`, `1-3`, or `3` for slide position 3.
  String get label =>
      isSlide ? '$position' : (valves.isEmpty ? '0' : valves.join('-'));

  @override
  bool operator ==(Object other) =>
      other is Fingering &&
      other.position == position &&
      other.valves.length == valves.length &&
      other.label == label;

  @override
  int get hashCode => Object.hash(position, label);

  @override
  String toString() => isSlide ? 'pos $position' : 'valves $label';
}

/// Natural harmonics of an open tube.
abstract final class Partials {
  /// Equal-tempered semitones partial [n] sits above the fundamental.
  static int semitones(int n) => (12 * _log2(n.toDouble())).round();

  /// How far partial [n] is from equal temperament, in cents. The 5th is
  /// about 14¢ flat, the 7th 31¢ flat.
  static double cents(int n) => 1200 * _log2(n.toDouble()) - 100 * semitones(n);
}

/// One way to play a note: a fingering on a partial.
class FingeringOption {
  const FingeringOption({
    required this.fingering,
    required this.partial,
    required this.note,
  });

  final Fingering fingering;

  /// Harmonic number, 2 = the lowest normally played partial.
  final int partial;

  /// Sounding (concert) note.
  final Note note;

  /// Expected deviation with a well-tuned instrument, positive is sharp.
  double get tendencyCents => Partials.cents(partial) + fingering.comboCents;
}

/// Layout of one instrument's harmonic series and fingerings.
class FingeringSpec {
  const FingeringSpec({
    required this.system,
    required this.fundamentalMidi,
    required this.partials,
  });

  final FingeringSystem system;

  /// Sounding MIDI number of the open fundamental (partial 1).
  final int fundamentalMidi;

  /// Partials used for fingering, ascending. Out-of-tune ones (7th, 11th)
  /// are left out so they never become the standard fingering.
  final List<int> partials;

  static const _threeValves = [
    Fingering.valves([]),
    Fingering.valves([2]),
    Fingering.valves([1]),
    Fingering.valves([1, 2]),
    Fingering.valves([3]),
    Fingering.valves([2, 3]),
    Fingering.valves([1, 3]),
    Fingering.valves([1, 2, 3]),
  ];

  static const _fourValves = [
    Fingering.valves([]),
    Fingering.valves([2]),
    Fingering.valves([1]),
    Fingering.valves([1, 2]),
    Fingering.valves([3]),
    Fingering.valves([2, 3]),
    Fingering.valves([4]),
    Fingering.valves([1, 3]),
    Fingering.valves([2, 4]),
    Fingering.valves([1, 2, 3]),
    Fingering.valves([1, 4]),
    Fingering.valves([1, 2, 4]),
    Fingering.valves([2, 3, 4]),
    Fingering.valves([1, 3, 4]),
    Fingering.valves([1, 2, 3, 4]),
  ];

  static final _slide = [for (var p = 1; p <= 7; p++) Fingering.slide(p)];

  /// All fingerings in order of preference: for the same lowering, the
  /// earlier one is the standard (1-2 before 3, 4 before 1-3).
  List<Fingering> get fingerings => switch (system) {
    FingeringSystem.threeValves || FingeringSystem.fHorn => _threeValves,
    FingeringSystem.fourValves => _fourValves,
    FingeringSystem.slide => _slide,
  };

  int get valveCount => switch (system) {
    FingeringSystem.fourValves => 4,
    FingeringSystem.slide => 0,
    _ => 3,
  };

  static FingeringSpec of(Instrument instrument) => switch (instrument) {
    // B♭ trumpet / flugelhorn: written C4 is the 2nd partial.
    Instrument.trumpet || Instrument.flugelhorn => const FingeringSpec(
      system: FingeringSystem.threeValves,
      fundamentalMidi: 46, // B♭2
      partials: [2, 3, 4, 5, 6, 8],
    ),
    Instrument.baritoneTrebleClef => const FingeringSpec(
      system: FingeringSystem.threeValves,
      fundamentalMidi: 34, // B♭1
      partials: [2, 3, 4, 5, 6, 8],
    ),
    Instrument.mellophone => const FingeringSpec(
      system: FingeringSystem.threeValves,
      fundamentalMidi: 41, // F2
      partials: [2, 3, 4, 5, 6, 8],
    ),
    Instrument.altoHorn => const FingeringSpec(
      system: FingeringSystem.threeValves,
      fundamentalMidi: 39, // E♭2
      partials: [2, 3, 4, 5, 6, 8],
    ),
    // Horn in F: written C4 is the 4th partial, played up to the 16th.
    Instrument.frenchHorn => const FingeringSpec(
      system: FingeringSystem.fHorn,
      fundamentalMidi: 29, // F1
      partials: [2, 3, 4, 5, 6, 8, 9, 10, 12, 16],
    ),
    Instrument.trombone => const FingeringSpec(
      system: FingeringSystem.slide,
      fundamentalMidi: 34, // B♭1
      partials: [2, 3, 4, 5, 6, 8, 9, 10],
    ),
    Instrument.euphoniumBassClef => const FingeringSpec(
      system: FingeringSystem.fourValves,
      fundamentalMidi: 34, // B♭1
      partials: [2, 3, 4, 5, 6, 8, 9, 10],
    ),
    // BB♭ tuba, the most common band tuba.
    Instrument.tuba => const FingeringSpec(
      system: FingeringSystem.fourValves,
      fundamentalMidi: 22, // B♭0
      partials: [2, 3, 4, 5, 6, 8],
    ),
  };

  /// Sounding note of [partial] played with [fingering].
  Note noteOf(int partial, Fingering fingering) =>
      Note(fundamentalMidi + Partials.semitones(partial) - fingering.lowering);
}

/// Every playable note of an instrument with its fingerings.
class FingeringChart {
  FingeringChart(this.spec) {
    final order = spec.fingerings;
    for (final partial in spec.partials) {
      for (final fingering in order) {
        final note = spec.noteOf(partial, fingering);
        (_byMidi[note.midi] ??= []).add(
          FingeringOption(fingering: fingering, partial: partial, note: note),
        );
      }
    }
    for (final options in _byMidi.values) {
      options.sort((a, b) {
        final byLowering = a.fingering.lowering.compareTo(b.fingering.lowering);
        if (byLowering != 0) return byLowering;
        return order.indexOf(a.fingering).compareTo(order.indexOf(b.fingering));
      });
    }
  }

  factory FingeringChart.of(Instrument instrument) =>
      _cache[instrument] ??= FingeringChart(FingeringSpec.of(instrument));

  static final _cache = <Instrument, FingeringChart>{};

  final FingeringSpec spec;
  final _byMidi = <int, List<FingeringOption>>{};

  /// Ways to play the sounding [note], standard fingering first. Empty when
  /// the note is out of range.
  List<FingeringOption> optionsFor(Note note) =>
      List.unmodifiable(_byMidi[note.midi] ?? const []);

  int get lowestMidi => _byMidi.keys.reduce(math.min);
  int get highestMidi => _byMidi.keys.reduce(math.max);

  /// Every note in range, low to high (sounding pitch).
  List<Note> get notes => [
    for (var m = lowestMidi; m <= highestMidi; m++)
      if (_byMidi.containsKey(m)) Note(m),
  ];
}

double _log2(double x) => math.log(x) / math.ln2;
