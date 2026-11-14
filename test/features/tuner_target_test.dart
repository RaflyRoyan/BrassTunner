import 'dart:math' as math;

import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:brass_tunner/features/tuner/domain/pitch_trace.dart';
import 'package:brass_tunner/features/tuner/presentation/pitch_trace_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

double hz(int midi, [double cents = 0]) =>
    440 * math.pow(2, (midi - 69 + cents / 100) / 12).toDouble();

Duration ms(int value) => Duration(milliseconds: value);

String targetText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('targetNote'))).data!;

void main() {
  group('PitchTrace', () {
    test('stores fractional MIDI pitch', () {
      final trace = PitchTrace()..add(ms(0), readingAt(hz(69, 12)));
      expect(trace.points.single.midi, closeTo(69.12, 0.001));
    });

    test('silence leaves one gap marker that tracks time', () {
      final trace = PitchTrace()
        ..add(ms(0), null) // nothing before the first note
        ..add(ms(100), readingAt(hz(60)))
        ..add(ms(200), null)
        ..add(ms(300), null)
        ..add(ms(400), readingAt(hz(62)));
      expect(trace.points.map((p) => p.midi?.round()), [60, null, 62]);
      expect(trace.points[1].seconds, closeTo(0.3, 1e-9));
      expect(trace.now, closeTo(0.4, 1e-9));
    });

    test('drops points older than the window, keeping one at the edge', () {
      final trace = PitchTrace(window: const Duration(seconds: 2));
      for (var t = 0; t <= 5000; t += 500) {
        trace.add(ms(t), readingAt(hz(60)));
      }
      final first = trace.points.first.seconds;
      expect(first, lessThan(3));
      expect(first, greaterThanOrEqualTo(2.5));
      expect(trace.points.last.seconds, 5);
    });
  });

  group('tuner target', () {
    testWidgets('shows the target in written pitch with input/output graph', (
      tester,
    ) async {
      await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
      // Default drone note concert B♭3 = written C4 on B♭ trumpet.
      expect(targetText(tester), 'C4');
      expect(find.text('Concert B♭3 · 233,1 Hz'), findsOneWidget);
      expect(find.byType(PitchTraceChart), findsOneWidget);
      expect(find.text('Input (Anda)'), findsOneWidget);
      expect(find.text('Output (target)'), findsOneWidget);
    });

    testWidgets('semitone arrows move the target and persist it', (
      tester,
    ) async {
      final app = await pumpApp(
        tester,
        tuner: const TunerState(TunerStatus.listening),
      );
      await tester.tap(find.byTooltip('Naik setengah nada'));
      await tester.pump();
      expect(targetText(tester), 'D♭4');
      await tester.tap(find.byTooltip('Turun setengah nada'));
      await tester.pump();
      await tester.tap(find.byTooltip('Turun setengah nada'));
      await tester.pump();
      expect(targetText(tester), 'B3');
      expect(app.store.values['droneMidi'], 57);
    });

    testWidgets('choosing a written note in the sheet', (tester) async {
      final app = await pumpApp(
        tester,
        tuner: const TunerState(TunerStatus.listening),
      );
      await tester.tap(find.byKey(const Key('targetNote')));
      await tester.pumpAndSettle();
      expect(find.text('Pilih nada target'), findsOneWidget);
      await tester.tap(find.text('G'));
      await tester.pump();
      await tester.tap(find.byTooltip('Naikkan oktaf'));
      await tester.pumpAndSettle();
      expect(targetText(tester), 'G5');
      // Written G5 on B♭ trumpet sounds concert F5.
      expect(app.store.values['droneMidi'], 77);
    });

    testWidgets('play sounds the target, stop silences it', (tester) async {
      final app = await pumpApp(
        tester,
        tuner: const TunerState(TunerStatus.listening),
      );
      await tester.tap(find.byKey(const Key('targetPlay')));
      await tester.pump();
      expect(app.sink.setups, 1);
      expect(app.sink.fed, isNotEmpty);
      expect(find.text('Hentikan'), findsOneWidget);
      expect(find.textContaining('earphone'), findsOneWidget);

      await tester.tap(find.byKey(const Key('targetPlay')));
      await tester.pump();
      expect(find.text('Mainkan'), findsOneWidget);
      expect(find.textContaining('earphone'), findsNothing);
    });

    testWidgets('difference from the target in cents or semitones', (
      tester,
    ) async {
      String diff() =>
          tester.widget<Text>(find.byKey(const Key('targetDiff'))).data!;

      await pumpApp(
        tester,
        tuner: TunerState(TunerStatus.listening, readingAt(hz(58, -8))),
      );
      expect(diff(), 'Selisih target: −8¢');

      await pumpApp(
        tester,
        tuner: TunerState(TunerStatus.listening, readingAt(hz(60, 5))),
      );
      expect(diff(), 'Selisih target: +2 semiton');
    });
  });
}
