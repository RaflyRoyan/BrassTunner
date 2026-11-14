import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

double hz(int midi) => NoteMapper().frequencyOf(Note(midi));

FakeTunerController fakeTuner(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NavigationBar)))
            .read(tunerControllerProvider.notifier)
        as FakeTunerController;

void main() {
  testWidgets('tuner shows the fingering and a tip for trumpet low D', (
    tester,
  ) async {
    // Concert C4 = written D4 on B♭ trumpet, played 1-3.
    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(hz(60))),
    );
    expect(find.byKey(const Key('fingering')), findsOneWidget);
    expect(find.bySemanticsLabel('Valve 1-3'), findsOneWidget);
    expect(find.textContaining('Cenderung sharp'), findsOneWidget);
    expect(find.textContaining('Tarik slide valve 3'), findsOneWidget);
  });

  testWidgets('open notes show no tip', (tester) async {
    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(hz(58))), // C4 written
    );
    expect(find.bySemanticsLabel('Terbuka'), findsOneWidget);
    expect(find.textContaining('Cenderung'), findsNothing);
  });

  testWidgets('trombone shows slide positions', (tester) async {
    await pumpApp(
      tester,
      stored: {'instrument': 'trombone'},
      tuner: TunerState(TunerStatus.listening, readingAt(hz(48))), // C3
    );
    expect(find.text('Posisi 6'), findsOneWidget);
  });

  testWidgets('fingering chart lists the instrument range', (tester) async {
    await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
    await tester.tap(find.byTooltip('Tabel penjarian'));
    await tester.pumpAndSettle();
    expect(find.text('Tabel penjarian'), findsOneWidget);
    expect(find.text('Trumpet (B♭)'), findsOneWidget);
    // Highest note on top: written C6 = concert B♭5 (MIDI 82).
    expect(find.byKey(const ValueKey('chart-82')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('chart-52')), // written F♯3, the lowest
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('chart-52')), findsOneWidget);
  });

  testWidgets('lip slur: walks through the partials and summarises', (
    tester,
  ) async {
    await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
    await tester.tap(find.text('Lip slur'));
    await tester.pumpAndSettle();
    final tuner = fakeTuner(tester);
    expect(tuner.starts, greaterThan(0));
    expect(find.text('Mainkan C4'), findsOneWidget);

    // Narrow to partials 2–3: C4 G4 C4 written = B♭3 F4 B♭3 concert.
    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(const RangeValues(0, 1));
    await tester.pump();
    expect(find.text('Partial 2–3'), findsOneWidget);

    for (final midi in [58, 65, 58]) {
      // The tracker needs the note held for 250 ms of wall-clock time.
      for (var i = 0; i < 8; i++) {
        tuner.emit(readingAt(hz(midi)));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
      }
      tuner.emit(null);
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('slurSummary')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Selesai!'), findsOneWidget);
    expect(find.text('Tidak ada nada meleset'), findsOneWidget);

    await tester.tap(find.text('Ulangi'));
    await tester.pump();
    expect(find.text('Mainkan C4'), findsOneWidget);
  });
}
