import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_shell.dart';
import 'features/settings/application/settings_controller.dart';
import 'l10n/app_localizations.dart';

/// Brass gold, also used for the launcher icon and splash.
const brandColor = Color(0xFFC9A227);

ThemeData buildTheme(
  Brightness brightness, {
  List<String>? fontFamilyFallback,
}) => ThemeData(
  colorSchemeSeed: brandColor,
  brightness: brightness,
  fontFamilyFallback: fontFamilyFallback,
);

class BrassTunerApp extends ConsumerWidget {
  const BrassTunerApp({super.key, this.fontFamilyFallback});

  /// Extra fonts for glyphs the default font lacks (e.g. ♭ in tests, where
  /// there is no system font fallback).
  final List<String>? fontFamilyFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Indonesian is the default UI language; English is ready for later.
      locale: const Locale('id'),
      theme: buildTheme(
        Brightness.light,
        fontFamilyFallback: fontFamilyFallback,
      ),
      darkTheme: buildTheme(
        Brightness.dark,
        fontFamilyFallback: fontFamilyFallback,
      ),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
