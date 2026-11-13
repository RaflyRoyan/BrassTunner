import 'package:flutter/material.dart';

import 'features/home/home_shell.dart';
import 'l10n/app_localizations.dart';

class BrassTunerApp extends StatelessWidget {
  const BrassTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Indonesian is the default UI language; English is ready for later.
      locale: const Locale('id'),
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC9A227),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFC9A227),
        brightness: Brightness.dark,
      ),
      home: const HomeShell(),
    );
  }
}
