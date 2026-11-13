import 'dart:math' as math;

import 'package:brass_tunner/features/long_tone/application/long_tone_controller.dart';
import 'package:brass_tunner/features/long_tone/domain/long_tone_tracker.dart';
import 'package:brass_tunner/features/settings/application/settings_controller.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

double plusCents(double hz, double c) => hz * math.pow(2, c / 1200);

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  group('LongToneTracker', () {
    test('records a held note relative to its pitch', () {
      final t = LongToneTracker();
      for (var i = 0; i <= 50; i++) {
        t.add(ms(i * 20), readingAt(plusCents(233.08, i.isEven ? 4 : -2)));
      }
      final take = t.current!;
      expect(take.note.label, 'B♭3');
      expect(take.durationSeconds, closeTo(1.0, 1e-9));
      expect(take.meanCents, closeTo(1.06, 0.1));
      expect(take.stabilityCents, closeTo(3, 0.1));
      expect(take.inTuneRatio(), 1);
    });

    test('drifting past 50 cents stays in the same take', () {
      final t = LongToneTracker();
      t.add(ms(0), readingAt(233.08));
      t.add(ms(20), readingAt(plusCents(233.08, 70))); // nearest note is B3
      expect(t.current!.note.label, 'B♭3');
      expect(t.current!.points.last.cents, closeTo(70, 0.5));
    });

    test('losing the pitch finishes the take', () {
      final t = LongToneTracker();
      for (var i = 0; i < 40; i++) {
        t.add(ms(i * 20), readingAt(233.08));
      }
      t.add(ms(800), null);
      expect(t.current, isNull);
      expect(t.last!.note.label, 'B♭3');
    });

    test('takes shorter than the minimum are discarded', () {
      final t = LongToneTracker();
      t.add(ms(0), readingAt(233.08));
      t.add(ms(200), readingAt(233.08));
      t.add(ms(220), null);
      expect(t.last, isNull);
    });

    test('a new note must persist before it starts a new take', () {
      final t = LongToneTracker();
      for (var i = 0; i < 40; i++) {
        t.add(ms(i * 20), readingAt(233.08));
      }
      // One stray frame of F4 is ignored.
      t.add(ms(800), readingAt(349.23));
      t.add(ms(820), readingAt(233.08));
      expect(t.current!.note.label, 'B♭3');

      // F4 held for 150 ms switches takes.
      for (var i = 0; i <= 8; i++) {
        t.add(ms(840 + i * 20), readingAt(349.23));
      }
      expect(t.current!.note.label, 'F4');
      expect(t.last!.note.label, 'B♭3');
    });
  });

  test('LongToneController records readings from the tuner', () {
    final tuner = FakeTunerController(const TunerState(TunerStatus.listening));
    final container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryStore()),
        tunerControllerProvider.overrideWith(() => tuner),
      ],
    );
    addTearDown(container.dispose);
    container.listen(longToneProvider, (_, _) {});

    tuner.emit(readingAt(233.08));
    tuner.emit(readingAt(plusCents(233.08, 10)));
    final state = container.read(longToneProvider);
    expect(state.isLive, isTrue);
    expect(state.current!.points.length, 2);
    expect(state.current!.points.last.cents, closeTo(10, 0.5));
  });
}
