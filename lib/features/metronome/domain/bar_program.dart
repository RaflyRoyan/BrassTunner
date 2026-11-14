/// A run of bars in one time signature, e.g. 4/4 for 4 bars.
class BarSegment {
  const BarSegment({this.beats = 4, this.unit = 4, this.bars = 4});

  static const int maxBeats = 12;
  static const int maxBars = 99;
  static const List<int> units = [2, 4, 8];

  /// Clicks per bar (time signature numerator).
  final int beats;

  /// Note value of one click (time signature denominator). The metronome
  /// clicks once per [unit]; BPM counts these clicks.
  final int unit;

  /// How many bars this segment lasts.
  final int bars;

  String get signature => '$beats/$unit';

  BarSegment copyWith({int? beats, int? unit, int? bars}) => BarSegment(
    beats: (beats ?? this.beats).clamp(1, maxBeats),
    unit: units.contains(unit) ? unit! : this.unit,
    bars: (bars ?? this.bars).clamp(1, maxBars),
  );

  @override
  bool operator ==(Object other) =>
      other is BarSegment &&
      other.beats == beats &&
      other.unit == unit &&
      other.bars == bars;

  @override
  int get hashCode => Object.hash(beats, unit, bars);
}

/// Where a bar of the program falls.
class BarPosition {
  const BarPosition(this.segment, this.barInSegment);

  /// Index into [BarProgram.segments].
  final int segment;

  /// 0-based bar within that segment.
  final int barInSegment;
}

/// Sequence of segments the metronome plays in order, then repeats, e.g.
/// 4/4 × 4 bars then 3/4 × 6 bars.
class BarProgram {
  BarProgram(List<BarSegment> segments)
    : segments = List.unmodifiable(
        segments.isEmpty ? const [BarSegment()] : segments,
      );

  static const int maxSegments = 16;

  /// Default: 4/4 × 4, then 3/4 × 4.
  static final BarProgram example = BarProgram(const [
    BarSegment(beats: 4, bars: 4),
    BarSegment(beats: 3, bars: 4),
  ]);

  final List<BarSegment> segments;

  int get totalBars => segments.fold(0, (sum, s) => sum + s.bars);

  /// Clicks for every bar in play order, for the metronome voice.
  List<int> get barBeats => [
    for (final s in segments) ...List.filled(s.bars, s.beats),
  ];

  /// Segment and bar for [bar], counted from the start; wraps around.
  BarPosition locate(int bar) {
    var remaining = bar % totalBars;
    for (var i = 0; i < segments.length; i++) {
      if (remaining < segments[i].bars) return BarPosition(i, remaining);
      remaining -= segments[i].bars;
    }
    return const BarPosition(0, 0); // unreachable
  }

  BarProgram replace(int index, BarSegment segment) =>
      BarProgram([...segments]..[index] = segment);

  BarProgram add() => segments.length >= maxSegments
      ? this
      : BarProgram([...segments, segments.last]);

  BarProgram removeAt(int index) =>
      segments.length <= 1 ? this : BarProgram([...segments]..removeAt(index));

  /// Compact storage form: `4/4x4,3/4x6`.
  String encode() => segments.map((s) => '${s.signature}x${s.bars}').join(',');

  /// Parses [encode] output; null if malformed.
  static BarProgram? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    final pattern = RegExp(r'^(\d+)/(\d+)x(\d+)$');
    final segments = <BarSegment>[];
    for (final part in text.split(',')) {
      final m = pattern.firstMatch(part);
      if (m == null) return null;
      final beats = int.parse(m[1]!);
      final unit = int.parse(m[2]!);
      final bars = int.parse(m[3]!);
      if (beats < 1 ||
          beats > BarSegment.maxBeats ||
          !BarSegment.units.contains(unit) ||
          bars < 1 ||
          bars > BarSegment.maxBars) {
        return null;
      }
      segments.add(BarSegment(beats: beats, unit: unit, bars: bars));
    }
    if (segments.length > maxSegments) return null;
    return BarProgram(segments);
  }

  @override
  bool operator ==(Object other) =>
      other is BarProgram &&
      other.segments.length == segments.length &&
      [
        for (var i = 0; i < segments.length; i++)
          other.segments[i] == segments[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hashAll(segments);
}
