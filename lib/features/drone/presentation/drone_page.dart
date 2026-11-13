import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../core/synth/oscillator.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/application/settings_controller.dart';
import '../application/drone_controller.dart';

class DronePage extends ConsumerWidget {
  const DronePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final drone = ref.watch(droneProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(droneProvider.notifier);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final frequency = NoteMapper(a4: settings.a4).frequencyOf(drone.note);
    final written = settings.instrument.writtenNote(drone.note);
    final octave = drone.note.octave;
    final muted = theme.colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          drone.note.label,
          key: const Key('droneNote'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          [
            if (settings.instrument.isTransposing)
              l10n.droneWritten(written.label),
            '${NumberFormat('0.00', locale).format(frequency)} Hz',
          ].join(' · '),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            for (var pc = 0; pc < 12; pc++)
              _NoteButton(
                label: Note(pc).name,
                selected: drone.note.pitchClass == pc,
                onPressed: () => controller.setPitchClass(pc),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: l10n.lowerOctave,
              onPressed: octave > DroneState.minOctave
                  ? () => controller.setOctave(octave - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 120,
              child: Text(
                l10n.droneOctave(octave),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: l10n.raiseOctave,
              onPressed: octave < DroneState.maxOctave
                  ? () => controller.setOctave(octave + 1)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: SegmentedButton<Waveform>(
            segments: [
              ButtonSegment(value: Waveform.sine, label: Text(l10n.waveSine)),
              ButtonSegment(value: Waveform.saw, label: Text(l10n.waveSaw)),
            ],
            selected: {drone.waveform},
            onSelectionChanged: (s) => controller.setWaveform(s.single),
          ),
        ),
        const SizedBox(height: 8),
        _VolumeSlider(value: drone.volume, onChanged: controller.setVolume),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: controller.toggle,
          icon: Icon(drone.playing ? Icons.stop : Icons.play_arrow),
          label: Text(drone.playing ? l10n.stop : l10n.play),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.droneFeedbackHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _NoteButton extends StatelessWidget {
  const _NoteButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.zero;
    final text = Text(label, style: const TextStyle(fontSize: 16));
    return selected
        ? FilledButton(
            style: FilledButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: text,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: text,
          );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.volume_down, semanticLabel: l10n.volume),
        Expanded(
          child: Slider(value: value, onChanged: onChanged),
        ),
        const Icon(Icons.volume_up),
      ],
    );
  }
}
