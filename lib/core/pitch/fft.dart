import 'dart:math' as math;
import 'dart:typed_data';

/// In-place iterative radix-2 complex FFT with precomputed twiddle and
/// bit-reversal tables, so repeated transforms of the same size allocate
/// nothing.
class Fft {
  Fft(this.size)
    : _cos = Float64List(size ~/ 2),
      _sin = Float64List(size ~/ 2),
      _bitReversed = Int32List(size) {
    if (size < 2 || (size & (size - 1)) != 0) {
      throw ArgumentError.value(size, 'size', 'must be a power of two >= 2');
    }
    for (var i = 0; i < size ~/ 2; i++) {
      final angle = -2 * math.pi * i / size;
      _cos[i] = math.cos(angle);
      _sin[i] = math.sin(angle);
    }
    var bits = 0;
    while ((1 << bits) < size) {
      bits++;
    }
    for (var i = 0; i < size; i++) {
      var reversed = 0;
      for (var b = 0; b < bits; b++) {
        if ((i >> b) & 1 == 1) reversed |= 1 << (bits - 1 - b);
      }
      _bitReversed[i] = reversed;
    }
  }

  final int size;
  final Float64List _cos;
  final Float64List _sin;
  final Int32List _bitReversed;

  /// Forward transform of ([re], [im]) in place. Both lists must have
  /// length [size].
  void transform(Float64List re, Float64List im) {
    final n = size;
    for (var i = 0; i < n; i++) {
      final j = _bitReversed[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var start = 0; start < n; start += len) {
        for (var k = 0; k < half; k++) {
          final wr = _cos[k * step];
          final wi = _sin[k * step];
          final a = start + k;
          final b = a + half;
          final tr = re[b] * wr - im[b] * wi;
          final ti = re[b] * wi + im[b] * wr;
          re[b] = re[a] - tr;
          im[b] = im[a] - ti;
          re[a] += tr;
          im[a] += ti;
        }
      }
    }
  }
}
