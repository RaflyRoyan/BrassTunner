import '../../../core/pitch/pitch_tracker.dart';

/// One input sample on the tuner graph.
class TracePoint {
  const TracePoint(this.seconds, this.midi);

  /// Time since the trace started.
  final double seconds;

  /// Detected concert pitch as a fractional MIDI number (69.12 = A4 +12¢),
  /// or null where no pitch was heard (draws a gap).
  final double? midi;
}

/// Rolling history of the detected pitch over the last [window].
class PitchTrace {
  PitchTrace({this.window = const Duration(seconds: 8)});

  final Duration window;
  final List<TracePoint> _points = [];

  List<TracePoint> get points => List.unmodifiable(_points);

  /// Time of the newest sample, the right edge of the graph.
  double get now => _points.isEmpty ? 0 : _points.last.seconds;

  double get windowSeconds => window.inMicroseconds / 1e6;

  void add(Duration time, TunerReading? reading) {
    final seconds = time.inMicroseconds / 1e6;
    final midi = reading == null
        ? null
        : reading.note.note.midi + reading.note.cents / 100;
    // Consecutive silences collapse into a single gap marker.
    if (midi == null && (_points.isEmpty || _points.last.midi == null)) {
      if (_points.isNotEmpty) {
        _points[_points.length - 1] = TracePoint(seconds, null);
      }
      return;
    }
    _points.add(TracePoint(seconds, midi));
    // Keep one point left of the window so the line enters from the edge.
    final cutoff = seconds - windowSeconds;
    var drop = 0;
    while (drop + 1 < _points.length && _points[drop + 1].seconds < cutoff) {
      drop++;
    }
    if (drop > 0) _points.removeRange(0, drop);
  }

  void clear() => _points.clear();
}
