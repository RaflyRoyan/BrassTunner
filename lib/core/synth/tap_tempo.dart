import 'metronome_voice.dart';

/// Derives BPM from the average interval of the last few taps.
class TapTempo {
  TapTempo({this.maxGap = const Duration(seconds: 2), this.maxTaps = 5});

  /// A longer pause starts a new measurement.
  final Duration maxGap;
  final int maxTaps;

  final List<Duration> _taps = [];

  /// Registers a tap at [now] (any monotonic clock). Returns the BPM once
  /// there are at least two taps.
  int? tap(Duration now) {
    if (_taps.isNotEmpty && now - _taps.last > maxGap) _taps.clear();
    _taps.add(now);
    if (_taps.length > maxTaps) _taps.removeAt(0);
    if (_taps.length < 2) return null;
    final span = _taps.last - _taps.first;
    final interval = span.inMicroseconds / (_taps.length - 1);
    if (interval <= 0) return null;
    return (60e6 / interval).round().clamp(
      MetronomeVoice.minBpm,
      MetronomeVoice.maxBpm,
    );
  }

  void reset() => _taps.clear();
}
