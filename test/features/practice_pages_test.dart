import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Future<TestApp> openTab(WidgetTester tester, String label) async {
  final app = await pumpApp(
    tester,
    tuner: const TunerState(TunerStatus.listening),
  );
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('drone: choose a note and octave, play and stop', (tester) async {
    final app = await openTab(tester, 'Drone');
    expect(find.byKey(const Key('droneNote')), findsOneWidget);
    expect(find.text('B♭3'), findsOneWidget);
    expect(find.textContaining('Tertulis C4'), findsOneWidget); // trumpet

    await tester.tap(find.text('F'));
    await tester.tap(find.byTooltip('Naikkan oktaf'));
    await tester.pumpAndSettle();
    expect(find.text('F4'), findsOneWidget);
    expect(find.textContaining('349,23 Hz'), findsOneWidget);
    expect(app.store.values['droneMidi'], 65);

    await tester.scrollUntilVisible(
      find.text('Mainkan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mainkan'));
    await tester.pump();
    expect(app.sink.setups, 1);
    expect(app.sink.fed, isNotEmpty);

    await tester.tap(find.text('Hentikan'));
    await tester.pump();
    expect(find.text('Mainkan'), findsOneWidget);
  });

  testWidgets('metronome: adjust tempo and beats, start it', (tester) async {
    final app = await openTab(tester, 'Metronom');
    expect(find.byKey(const Key('bpm')), findsOneWidget);
    expect(find.text('80'), findsOneWidget);

    await tester.tap(find.byTooltip('Lebih cepat'));
    await tester.tap(find.byTooltip('Kurangi ketukan'));
    await tester.pumpAndSettle();
    expect(find.text('81'), findsOneWidget);
    expect(find.text('3 ketukan per birama'), findsOneWidget);
    expect(app.store.values['metronomeBpm'], 81);

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

  testWidgets('metronome can be started from the tuner tab', (tester) async {
    final app = await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.text('♩ = 80'));
    await tester.pump();
    expect(app.sink.setups, 1);
    await tester.tap(find.text('♩ = 80'));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('long tone tab shows a hint before a note is held', (
    tester,
  ) async {
    await openTab(tester, 'Nada panjang');
    expect(find.text('Tahan sebuah nada untuk mulai merekam'), findsOneWidget);
  });

  testWidgets('mic runs only on the tuner and long-tone tabs', (tester) async {
    await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
    // The fake controller counts start/stop calls.
    final tuner = ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    ).read(tunerControllerProvider.notifier) as FakeTunerController;
    final startsBefore = tuner.starts;

    await tester.tap(find.text('Drone'));
    await tester.pumpAndSettle();
    expect(tuner.stops, greaterThan(0));

    await tester.tap(find.text('Tuner').last);
    await tester.pumpAndSettle();
    expect(tuner.starts, greaterThan(startsBefore));
  });
}
