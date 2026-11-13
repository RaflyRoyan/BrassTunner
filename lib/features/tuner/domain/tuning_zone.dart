/// How close a note is to pitch, for the tuner's colour coding.
enum TuningZone {
  /// Within ±5 cents.
  inTune,

  /// Within ±15 cents.
  close,

  /// More than 15 cents away.
  off;

  static const double inTuneCents = 5;
  static const double closeCents = 15;

  static TuningZone of(double cents) {
    final deviation = cents.abs();
    if (deviation <= inTuneCents) return TuningZone.inTune;
    if (deviation <= closeCents) return TuningZone.close;
    return TuningZone.off;
  }
}
