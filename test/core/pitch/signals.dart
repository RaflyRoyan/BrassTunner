import 'dart:math' as math;
import 'dart:typed_data';

/// Synthetic test signals. All amplitudes are in -1..1 float PCM.

const double sampleRate = 44100;

Float32List sine(
  double frequency, {
  int length = 4096,
  double amplitude = 0.5,
  double phase = 0,
  int startSample = 0,
}) {
  final out = Float32List(length);
  for (var i = 0; i < length; i++) {
    out[i] =
        amplitude *
        math.sin(
          2 * math.pi * frequency * (i + startSample) / sampleRate + phase,
        );
  }
  return out;
}

/// Brass-like spectrum: strong low harmonics rolling off.
const brassHarmonics = [1.0, 0.8, 0.6, 0.5, 0.4, 0.3, 0.2, 0.15];

/// Low brass notes often have a fundamental weaker than the 2nd harmonic.
const weakFundamentalHarmonics = [0.25, 1.0, 0.8, 0.6, 0.4, 0.3];

/// Sum of harmonics with seeded random phases, normalized to [peak].
Float32List harmonic(
  double frequency, {
  List<double> amplitudes = brassHarmonics,
  int length = 4096,
  double peak = 0.5,
  int seed = 1,
}) {
  final random = math.Random(seed);
  final phases = [for (var _ in amplitudes) random.nextDouble() * 2 * math.pi];
  final out = Float32List(length);
  var maxAbs = 0.0;
  for (var i = 0; i < length; i++) {
    var v = 0.0;
    for (var h = 0; h < amplitudes.length; h++) {
      final f = frequency * (h + 1);
      if (f >= sampleRate / 2) break;
      v +=
          amplitudes[h] *
          math.sin(2 * math.pi * f * i / sampleRate + phases[h]);
    }
    out[i] = v;
    if (v.abs() > maxAbs) maxAbs = v.abs();
  }
  for (var i = 0; i < length; i++) {
    out[i] = out[i] / maxAbs * peak;
  }
  return out;
}

/// Adds seeded uniform white noise of the given peak amplitude.
Float32List withNoise(
  Float32List signal,
  double noiseAmplitude, {
  int seed = 7,
}) {
  final random = math.Random(seed);
  return Float32List.fromList([
    for (final s in signal) s + (random.nextDouble() * 2 - 1) * noiseAmplitude,
  ]);
}

Float32List whiteNoise(double amplitude, {int length = 4096, int seed = 3}) =>
    withNoise(Float32List(length), amplitude, seed: seed);

/// Signed error of [measured] relative to [expected], in cents.
double centsError(double measured, double expected) =>
    1200 * math.log(measured / expected) / math.ln2;
