import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

ThemeMode appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets('theme follows the system until the user picks one', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    expect(appThemeMode(tester), ThemeMode.system);

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(appThemeMode(tester), ThemeMode.dark);
    expect(app.store.values['themeMode'], 'dark');
  });

  testWidgets('stored theme is restored', (tester) async {
    await pumpApp(tester, stored: {'themeMode': 'light'});
    expect(appThemeMode(tester), ThemeMode.light);
  });

  testWidgets('screen stays on only while the mic listens', (tester) async {
    final app = await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.listening),
    );
    expect(app.wakeLock.enabled, isTrue);

    final tuner = ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    ).read(tunerControllerProvider.notifier) as FakeTunerController;
    tuner.state = TunerState.idle;
    await tester.pump();
    expect(app.wakeLock.enabled, isFalse);

    tuner.state = const TunerState(TunerStatus.permissionDenied);
    await tester.pump();
    expect(app.wakeLock.enabled, isFalse);
  });
}
