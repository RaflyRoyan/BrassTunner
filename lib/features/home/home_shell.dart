import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../drone/application/drone_controller.dart';
import '../drone/presentation/drone_page.dart';
import '../fingering/presentation/fingering_chart_page.dart';
import '../history/application/history_controller.dart';
import '../history/presentation/history_page.dart';
import '../../shared/platform/screen_wake_lock.dart';
import '../lip_slur/presentation/lip_slur_page.dart';
import '../long_tone/presentation/long_tone_page.dart';
import '../metronome/application/metronome_controller.dart';
import '../metronome/presentation/metronome_page.dart';
import '../settings/presentation/settings_screen.dart';
import '../tuner/application/tuner_controller.dart';
import '../tuner/presentation/tuner_screen.dart';

enum HomeTab {
  tuner,
  longTone,
  lipSlur,
  drone,
  metronome;

  bool get needsMic => this == tuner || this == longTone || this == lipSlur;
}

/// Bottom-navigation shell. Owns the mic lifecycle: listening only on tabs
/// that need it and only while the app is visible.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final AppLifecycleListener _lifecycle;
  HomeTab _tab = HomeTab.tuner;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // Starts recording practice sessions in the background.
    ref.read(sessionRecorderProvider);
    // Screen stays on exactly while the mic is listening.
    final wakeLock = ref.read(screenWakeLockProvider);
    ref.listenManual(
      tunerControllerProvider.select((s) => s.status == TunerStatus.listening),
      (_, listening) => wakeLock.setEnabled(listening),
      fireImmediately: true,
    );
    _lifecycle = AppLifecycleListener(
      onShow: () {
        _visible = true;
        _syncMic();
      },
      onHide: () {
        _visible = false;
        _syncMic();
        // No background audio: stop sound when the user leaves the app.
        ref.read(droneProvider.notifier).stop();
        if (ref.read(metronomeProvider).running) {
          ref.read(metronomeProvider.notifier).toggle();
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMic();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _syncMic() {
    final tuner = ref.read(tunerControllerProvider.notifier);
    if (_visible && _tab.needsMic) {
      tuner.start();
    } else {
      tuner.stop();
    }
  }

  void _select(int index) {
    setState(() => _tab = HomeTab.values[index]);
    _syncMic();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = {
      HomeTab.tuner: l10n.appTitle,
      HomeTab.longTone: l10n.tabLongTone,
      HomeTab.lipSlur: l10n.tabLipSlur,
      HomeTab.drone: l10n.tabDrone,
      HomeTab.metronome: l10n.tabMetronome,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]!),
        actions: [
          IconButton(
            tooltip: l10n.fingeringChartTitle,
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FingeringChartPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.historyTitle,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
            ),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_tab) {
          HomeTab.tuner => const TunerPage(),
          HomeTab.longTone => const LongTonePage(),
          HomeTab.lipSlur => const LipSlurPage(),
          HomeTab.drone => const DronePage(),
          HomeTab.metronome => const MetronomePage(),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.tune),
            label: l10n.tabTuner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.tabLongTone,
          ),
          NavigationDestination(
            icon: const Icon(Icons.stairs_outlined),
            label: l10n.tabLipSlur,
          ),
          NavigationDestination(
            icon: const Icon(Icons.graphic_eq),
            label: l10n.tabDrone,
          ),
          NavigationDestination(
            icon: const Icon(Icons.av_timer),
            label: l10n.tabMetronome,
          ),
        ],
      ),
    );
  }
}
