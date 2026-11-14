import 'dart:math' as math;

import 'package:brass_tunner/core/synth/metronome_voice.dart';
import 'package:brass_tunner/core/synth/synth_engine.dart';
import 'package:brass_tunner/features/metronome/domain/bar_program.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Renders [seconds] of audio and returns every click.
List<BeatEvent> clicks(SynthEngine engine, double seconds) {
  final events = <BeatEvent>[];
  final total = (44100 * seconds).round();
  for (var at = 0; at < total; at += 1000) {
    events.addAll(engine.render(math.min(1000, total - at)).beats);
  }
  return events;
}

void main() {
  group('BarProgram', () {
    final program = BarProgram(const [
      BarSegment(beats: 4, bars: 4),
      BarSegment(beats: 3, bars: 6),
    ]);

    test('expands to beats per bar in play order', () {
      expect(program.totalBars, 10);
      expect(program.barBeats, [4, 4, 4, 4, 3, 3, 3, 3, 3, 3]);
    });

    test('locates bars and wraps around', () {
      BarPosition at(int bar) => program.locate(bar);
      expect((at(0).segment, at(0).barInSegment), (0, 0));
      expect((at(3).segment, at(3).barInSegment), (0, 3));
      expect((at(4).segment, at(4).barInSegment), (1, 0));
      expect((at(9).segment, at(9).barInSegment), (1, 5));
      expect((at(10).segment, at(10).barInSegment), (0, 0)); // repeat
    });

    test('encodes and decodes', () {
      final withUnit = program.replace(1, const BarSegment(beats: 6, unit: 8));
      expect(withUnit.encode(), '4/4x4,6/8x4');
      expect(BarProgram.decode(withUnit.encode()), withUnit);
      expect(BarProgram.decode('4/4x4,oops'), isNull);
      expect(BarProgram.decode('4/5x4'), isNull);
      expect(BarProgram.decode('0/4x4'), isNull);
      expect(BarProgram.decode(null), isNull);
    });

    test('keeps at least one segment', () {
      final single = BarProgram(const [BarSegment()]);
      expect(single.removeAt(0).segments.length, 1);
      expect(program.add().segments.last, program.segments.last);
    });
  });

  group('metronome bar pattern', () {
    test('plays the bars in order, then repeats, without stopping', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm =
            240 // 4 clicks per second
        ..barPattern = [2, 2, 3]
        ..start();
      final events = clicks(engine, 4.5); // 18 clicks
      expect(events.map((e) => e.beatInBar).take(14), [
        0, 1, 0, 1, 0, 1, 2, // first pass: 2/4, 2/4, 3/4
        0, 1, 0, 1, 0, 1, 2, // repeat
      ]);
      expect(events.map((e) => e.bar).take(8), [0, 0, 1, 1, 2, 2, 2, 3]);
    });

    test('switching patterns while running restarts at a downbeat', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm = 240
        ..beatsPerBar = 4
        ..start();
      clicks(engine, 0.6); // clicks 0, 1, 2 of a 4/4 bar
      engine.metronome.barPattern = [3];
      final next = clicks(engine, 1);
      expect(next.first.beatInBar, 0);
      expect(next.first.bar, 0);
      expect(engine.metronome.running, isTrue);
    });

    test('null pattern returns to beatsPerBar', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm = 240
        ..beatsPerBar = 2
        ..barPattern = [3]
        ..barPattern = null
        ..start();
      expect(clicks(engine, 1).map((e) => e.beatInBar), [0, 1, 0, 1]);
    });
  });

  group('metronome page', () {
    Future<TestApp> openMetronome(
      WidgetTester tester, {
      Map<String, Object>? stored,
    }) async {
      // Phone-sized screen (360 × 780 dp).
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final app = await pumpApp(
        tester,
        stored: stored,
        tuner: const TunerState(TunerStatus.listening),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Metronom'),
        ),
      );
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('multi meter: edit parts and persist the program', (
      tester,
    ) async {
      final app = await openMetronome(tester);
      await tester.tap(find.text('Multi birama'));
      await tester.pumpAndSettle();
      expect(app.store.values['metronomeMultiBar'], 1);
      // Default program 4/4 × 4, 3/4 × 4.
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      // Bar position is shown from the start of the program.
      expect(find.text('Bagian 1 · 4/4 · birama 1/4'), findsOneWidget);

      // Second part: 3/4 × 6.
      final second = find.byKey(const Key('segment1'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(
          find.descendant(
            of: second,
            matching: find.byTooltip('Tambah birama'),
          ),
        );
        await tester.pump();
      }
      expect(find.text('× 6 birama'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Tambah bagian'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Total 10 birama'), findsOneWidget);
      await tester.tap(find.text('Tambah bagian'));
      await tester.pumpAndSettle();
      expect(app.store.values['metronomeProgram'], '4/4x4,3/4x6,3/4x6');

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('segment2')),
          matching: find.byTooltip('Hapus bagian'),
        ),
      );
      await tester.pumpAndSettle();
      expect(app.store.values['metronomeProgram'], '4/4x4,3/4x6');
    });

    testWidgets('stored program loads and plays with the bar pattern', (
      tester,
    ) async {
      final app = await openMetronome(
        tester,
        stored: {'metronomeMultiBar': 1, 'metronomeProgram': '6/8x2,5/4x1'},
      );
      expect(find.text('6/8'), findsOneWidget);
      expect(find.text('5/4'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mainkan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mainkan'));
      await tester.pump();
      expect(app.sink.setups, 1);
      await tester.tap(find.text('Hentikan'));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('single meter keeps the beats stepper', (tester) async {
      await openMetronome(tester);
      expect(find.text('4 ketukan per birama'), findsOneWidget);
      expect(find.byKey(const Key('programPosition')), findsNothing);
    });
  });
}
