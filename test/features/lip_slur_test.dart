import 'dart:math' as math;

import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/fingering/domain/fingering.dart';
import 'package:brass_tunner/features/lip_slur/domain/lip_slur.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Duration ms(int v) => Duration(milliseconds: v);

double hzOf(Note n, [double cents = 0]) =>
    NoteMapper().frequencyOf(n) * math.pow(2, cents / 1200);

LipSlurExercise trumpetOpen({int low = 2, int high = 5}) => LipSlurExercise(
  spec: FingeringSpec.of(Instrument.trumpet),
  fingering: const Fingering.valves([]),
  lowPartial: low,
  highPartial: high,
);

/// Holds [note] from [start] for [length] ms in 20 ms frames.
int hold(
  LipSlurTracker t,
  int start,
  Note note, {
  int length = 300,
  double cents = 0,
}) {
  var time = start;
  for (; time <= start + length; time += 20) {
    t.add(ms(time), readingAt(hzOf(note, cents)));
  }
  return time;
}

void main() {
  group('LipSlurExercise', () {
    test('goes up and back down the partials', () {
      final e = trumpetOpen();
      expect(e.partials, [2, 3, 4, 5, 4, 3, 2]);
      // Concert B♭3 F4 B♭4 D5 B♭4 F4 B♭3 (written C4 G4 C5 E5 …).
      expect(e.targets.map((n) => n.label), [
        'B♭3', 'F4', 'B♭4', 'D5', 'B♭4', 'F4', 'B♭3', //
      ]);
    });

    test('a valve combination shifts every note', () {
      final e = LipSlurExercise(
        spec: FingeringSpec.of(Instrument.trumpet),
        fingering: const Fingering.valves([2]),
        lowPartial: 2,
        highPartial: 4,
      );
      expect(e.targets.map((n) => n.label), ['A3', 'E4', 'A4', 'E4', 'A3']);
    });

    test('skips partials the instrument does not use (7th)', () {
      expect(trumpetOpen(low: 5, high: 8).partials, [5, 6, 8, 6, 5]);
    });
  });

  group('LipSlurTracker', () {
    test('a clean run completes every step with its cents', () {
      final e = trumpetOpen(high: 3);
      final t = LipSlurTracker(e);
      var time = 0;
      for (final note in e.targets) {
        time = hold(t, time, note, cents: 4);
      }
      expect(t.finished, isTrue);
      expect(t.steps.every((s) => s.done), isTrue);
      expect(t.steps.first.meanCents, closeTo(4, 0.5));
      expect(t.meanAbsCents, closeTo(4, 0.5));
      expect(t.totalMisses, 0);
    });

    test('a short blip does not count', () {
      final t = LipSlurTracker(trumpetOpen());
      t.add(ms(0), readingAt(hzOf(t.steps[0].target)));
      t.add(ms(100), readingAt(hzOf(t.steps[0].target)));
      expect(t.index, 0);
    });

    test('cracking to the wrong partial is a miss, once per attempt', () {
      final e = trumpetOpen();
      final t = LipSlurTracker(e);
      var time = hold(t, 0, e.targets[0]);
      expect(t.index, 1);
      // Aimed for F4, landed on B♭4.
      time = hold(t, time, e.targets[2], length: 600);
      expect(t.steps[1].misses, 1);
      expect(t.index, 1);
      hold(t, time, e.targets[1]);
      expect(t.index, 2);
      expect(t.totalMisses, 1);
    });

    test('staying on the note just played is not a miss', () {
      final e = trumpetOpen();
      final t = LipSlurTracker(e);
      hold(t, 0, e.targets[0], length: 1000);
      expect(t.index, 1);
      expect(t.steps[1].misses, 0);
    });

    test('silence resets the hold', () {
      final e = trumpetOpen();
      final t = LipSlurTracker(e);
      final target = e.targets[0];
      t.add(ms(0), readingAt(hzOf(target)));
      t.add(ms(200), null);
      t.add(ms(220), readingAt(hzOf(target)));
      t.add(ms(300), readingAt(hzOf(target)));
      expect(t.index, 0);
    });
  });
}
