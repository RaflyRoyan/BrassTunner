// ignore_for_file: avoid_print
// Measures the cost of one tuner update (noise gate + MPM/YIN + smoothing)
// on a 4096-sample window, as run in the DSP isolate every 1024-sample hop.
//
//   dart run tool/benchmark_dsp.dart            # JIT
//   dart compile exe tool/benchmark_dsp.dart -o build/bench.exe && build/bench.exe
//
// AOT (`compile exe`) is closest to a release build on a phone. Phones are
// several times slower than a desktop CPU: a low-end ARM core (Cortex-A53)
// runs this roughly 5–10× slower, so keep the desktop median well under
// 23 ms / 10 ≈ 2.3 ms.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brass_tunner/core/pitch/pitch_tracker.dart';

const sampleRate = 44100.0;
const window = 4096;
const hop = 1024;
const hopMs = hop / sampleRate * 1000;

List<double> brassLike(double f) {
  final out = Float64List(window);
  for (var i = 0; i < window; i++) {
    final t = i / sampleRate;
    var s = 0.0;
    for (var h = 1; h <= 8; h++) {
      s += math.sin(2 * math.pi * f * h * t) / h;
    }
    out[i] = 0.3 * s;
  }
  return out;
}

void main() {
  final cases = {
    'tuba B♭1 58.27 Hz': brassLike(58.27),
    'trombone B♭2 116.5 Hz': brassLike(116.54),
    'trumpet B♭3 233.1 Hz': brassLike(233.08),
    'trumpet B♭5 932.3 Hz': brassLike(932.33),
    'silence (gated)': Float64List(window),
  };
  print('Hop budget: ${hopMs.toStringAsFixed(1)} ms per update\n');
  for (final MapEntry(key: name, value: frame) in cases.entries) {
    final tracker = PitchTracker();
    for (var i = 0; i < 50; i++) {
      tracker.process(frame); // warm-up (JIT, caches)
    }
    final times = <double>[];
    final sw = Stopwatch();
    for (var i = 0; i < 300; i++) {
      sw
        ..reset()
        ..start();
      tracker.process(frame);
      sw.stop();
      times.add(sw.elapsedMicroseconds / 1000);
    }
    times.sort();
    final median = times[times.length ~/ 2];
    final p95 = times[(times.length * 0.95).floor()];
    print(
      '${name.padRight(24)} median ${median.toStringAsFixed(3)} ms  '
      'p95 ${p95.toStringAsFixed(3)} ms  '
      '(${(median / hopMs * 100).toStringAsFixed(1)}% of hop)',
    );
  }
}
