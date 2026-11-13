import 'dart:typed_data';

import 'package:brass_tunner/core/audio/sliding_window.dart';
import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/core/pitch/pitch_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'signals.dart';

/// Streams [seconds] of [frequency] through a 4096/1024 sliding window, in
/// mic-sized chunks, and collects every tracker reading.
List<TunerReading?> stream(
  PitchTracker tracker,
  double frequency, {
  double seconds = 0.5,
  double amplitude = 0.5,
}) {
  final window = SlidingWindow();
  final readings = <TunerReading?>[];
  final total = (seconds * sampleRate).round();
  const chunk = 882; // 20 ms, an odd size on purpose
  for (var start = 0; start < total; start += chunk) {
    final samples = sine(
      frequency,
      length: chunk,
      amplitude: amplitude,
      startSample: start,
    );
    window.add(samples, (w) => readings.add(tracker.process(w)));
  }
  return readings;
}

void main() {
  test('steady B♭3 is reported as B♭3, in tune', () {
    final readings = stream(PitchTracker(), 233.08);
    final last = readings.last!;
    expect(last.note.note.label, 'B♭3');
    expect(last.note.cents.abs(), lessThan(1));
    expect(last.levelDb, closeTo(-9.03, 0.2));
  });

  test('a tone 20 cents sharp reads +20', () {
    final readings = stream(PitchTracker(), 233.08 * 1.011619); // +20¢
    expect(readings.last!.note.cents, closeTo(20, 1));
  });

  test('A4 = 442 calibration shifts the reading', () {
    final tracker = PitchTracker(mapper: NoteMapper(a4: 442));
    final last = stream(tracker, 440).last!;
    expect(last.note.note.label, 'A4');
    expect(last.note.cents, closeTo(-7.85, 1));
  });

  test('changing A4 mid-stream applies immediately', () {
    final tracker = PitchTracker();
    stream(tracker, 440, seconds: 0.3);
    tracker.mapper = tracker.mapper.copyWith(a4: 445);
    // A fresh SlidingWindow needs 4096 samples (~93 ms) before its first frame.
    final last = stream(tracker, 440, seconds: 0.1).last!;
    expect(last.note.cents, closeTo(-19.56, 1));
  });

  test('quiet input is gated out', () {
    final readings = stream(PitchTracker(), 233.08, amplitude: 0.001);
    expect(readings.every((r) => r == null), isTrue);
  });

  test('note change settles within a few frames', () {
    final tracker = PitchTracker();
    stream(tracker, 233.08, seconds: 0.3);
    final after = stream(tracker, 349.23, seconds: 0.2); // F4
    // Window holds old samples for 4 hops; median needs ~3 more frames.
    final settled = after.indexWhere((r) => r?.note.note.label == 'F4');
    expect(settled, inInclusiveRange(0, 7));
    expect(after.last!.note.cents.abs(), lessThan(1));
  });

  test('silence after a note clears the reading', () {
    final tracker = PitchTracker();
    stream(tracker, 233.08, seconds: 0.3);
    TunerReading? last;
    final window = SlidingWindow();
    for (var i = 0; i < 20; i++) {
      window.add(Float32List(1024), (w) => last = tracker.process(w));
    }
    expect(last, isNull);
  });
}
