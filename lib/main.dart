import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/drone/application/drone_controller.dart';
import 'features/metronome/application/metronome_controller.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/settings/data/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPreferencesStore.open({
    ...SettingsController.keys,
    ...DroneController.keys,
    ...MetronomeController.keys,
  });
  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      child: const BrassTunerApp(),
    ),
  );
}
