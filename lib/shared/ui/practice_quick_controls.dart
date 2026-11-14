import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/metronome/application/metronome_controller.dart';
import '../../l10n/app_localizations.dart';

/// Compact metronome toggle so it can run while the tuner is on screen.
/// The target tone has its own play button on the tuner.
class PracticeQuickControls extends ConsumerWidget {
  const PracticeQuickControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metronome = ref.watch(metronomeProvider);

    return Tooltip(
      message: l10n.tabMetronome,
      child: FilterChip(
        avatar: Icon(metronome.running ? Icons.stop : Icons.av_timer, size: 18),
        showCheckmark: false,
        selected: metronome.running,
        label: Text('♩ = ${metronome.bpm}'),
        onSelected: (_) => ref.read(metronomeProvider.notifier).toggle(),
      ),
    );
  }
}
