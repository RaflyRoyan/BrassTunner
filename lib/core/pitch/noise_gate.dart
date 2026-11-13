import 'dart:math' as math;

/// RMS noise gate with hysteresis: opens at [openThresholdDb], closes only
/// when the level falls below [closeThresholdDb]. The gap stops the tuner
/// flickering on and off while a note decays.
class NoiseGate {
  NoiseGate({this.openThresholdDb = -45, this.closeThresholdDb = -50}) {
    if (closeThresholdDb > openThresholdDb) {
      throw ArgumentError('closeThresholdDb must be <= openThresholdDb');
    }
  }

  /// Level in dBFS (0 = full scale) at which the gate opens.
  final double openThresholdDb;

  /// Level in dBFS below which an open gate closes.
  final double closeThresholdDb;

  bool _isOpen = false;
  bool get isOpen => _isOpen;

  /// RMS level in dBFS of the last processed frame.
  double lastLevelDb = double.negativeInfinity;

  /// Updates the gate with one frame and returns whether it is open.
  bool process(List<double> samples) {
    lastLevelDb = rmsDb(samples);
    _isOpen = _isOpen
        ? lastLevelDb >= closeThresholdDb
        : lastLevelDb >= openThresholdDb;
    return _isOpen;
  }

  void reset() {
    _isOpen = false;
    lastLevelDb = double.negativeInfinity;
  }

  /// RMS level in dBFS; negative infinity for silence or an empty frame.
  static double rmsDb(List<double> samples) {
    if (samples.isEmpty) return double.negativeInfinity;
    var sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    final rms = math.sqrt(sum / samples.length);
    if (rms <= 0) return double.negativeInfinity;
    return 20 * math.log(rms) / math.ln10;
  }
}
