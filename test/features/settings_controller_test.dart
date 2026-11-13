import 'package:brass_tunner/features/settings/application/settings_controller.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

ProviderContainer containerWith(InMemoryStore store) {
  final container = ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to A4 = 440 and trumpet', () {
    final settings = containerWith(InMemoryStore()).read(settingsProvider);
    expect(settings, const TunerSettings());
  });

  test('loads saved settings', () {
    final store = InMemoryStore({'a4': 442.0, 'instrument': 'tuba'});
    final settings = containerWith(store).read(settingsProvider);
    expect(settings.a4, 442);
    expect(settings.instrument, Instrument.tuba);
  });

  test('ignores corrupt or out-of-range saved values', () {
    final store = InMemoryStore({'a4': 500.0, 'instrument': 'kazoo'});
    expect(containerWith(store).read(settingsProvider), const TunerSettings());
  });

  test('setA4 rounds, clamps and persists', () async {
    final store = InMemoryStore();
    final container = containerWith(store);
    final controller = container.read(settingsProvider.notifier);

    await controller.setA4(441.6);
    expect(container.read(settingsProvider).a4, 442);
    expect(store.values['a4'], 442.0);

    await controller.setA4(460);
    expect(container.read(settingsProvider).a4, 450);
    await controller.setA4(400);
    expect(container.read(settingsProvider).a4, 430);
  });

  test('setInstrument persists by name', () async {
    final store = InMemoryStore();
    final container = containerWith(store);
    await container
        .read(settingsProvider.notifier)
        .setInstrument(Instrument.frenchHorn);
    expect(container.read(settingsProvider).instrument, Instrument.frenchHorn);
    expect(store.values['instrument'], 'frenchHorn');
  });
}
