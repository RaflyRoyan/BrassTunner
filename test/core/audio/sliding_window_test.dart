import 'dart:typed_data';

import 'package:brass_tunner/core/audio/sliding_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Feeds 0, 1, 2, … in chunks of [chunk] and returns copies of every window.
  List<Float32List> run(int total, int chunk, {int window = 8, int hop = 2}) {
    final sw = SlidingWindow(windowSize: window, hopSize: hop);
    final out = <Float32List>[];
    for (var start = 0; start < total; start += chunk) {
      final end = start + chunk > total ? total : start + chunk;
      sw.add([
        for (var i = start; i < end; i++) i.toDouble(),
      ], (w) => out.add(Float32List.fromList(w)));
    }
    return out;
  }

  for (final chunk in [1, 2, 3, 5, 8, 13]) {
    test('chunk size $chunk gives the same windows', () {
      final windows = run(20, chunk);
      // First window after 8 samples, then one per 2 new samples.
      expect(windows.length, 7);
      for (var w = 0; w < windows.length; w++) {
        expect(windows[w], [
          for (var i = 0; i < 8; i++) (w * 2 + i).toDouble(),
        ], reason: 'window $w');
      }
    });
  }

  test('no window until the buffer is full', () {
    expect(run(7, 7), isEmpty);
  });

  test('reset starts over', () {
    final sw = SlidingWindow(windowSize: 4, hopSize: 2);
    var count = 0;
    sw.add([1, 2, 3], (_) => count++);
    sw.reset();
    sw.add([1, 2, 3], (_) => count++);
    expect(count, 0);
  });

  test('rejects a hop larger than the window', () {
    expect(() => SlidingWindow(windowSize: 4, hopSize: 5), throwsArgumentError);
  });
}
