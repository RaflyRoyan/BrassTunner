import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/drone/application/drone_controller.dart';
import '../../features/metronome/application/metronome_controller.dart';
import '../../l10n/app_localizations.dart';

/// Compact metronome toggle (and drone stop, when playing) so both can run
/// while the tuner is on screen.
class PracticeQuickControls extends ConsumerWidget {
  const PracticeQuickControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metronome = ref.watch(metronomeProvider);
    final drone = ref.watch(droneProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (drone.playing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              avatar: const Icon(Icons.graphic_eq, size: 18),
              label: Text(l10n.droneChip(drone.note.label)),
              deleteButtonTooltipMessage: l10n.stopDrone,
              onDeleted: ref.read(droneProvider.notifier).stop,
            ),
          ),
        Tooltip(
          message: l10n.tabMetronome,
          child: FilterChip(
            avatar: Icon(
              metronome.running ? Icons.stop : Icons.av_timer,
              size: 18,
            ),
            showCheckmark: false,
            selected: metronome.running,
            label: Text('♩ = ${metronome.bpm}'),
            onSelected: (_) => ref.read(metronomeProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }
}
