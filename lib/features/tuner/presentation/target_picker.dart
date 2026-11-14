import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../drone/application/drone_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/instrument.dart';

/// Lowest and highest selectable target, concert MIDI.
const int _minMidi = (DroneState.minOctave + 1) * 12;
const int _maxMidi = (DroneState.maxOctave + 2) * 12 - 1;

/// Target note for the tuner, shared with the drone so the same tone plays.
/// Shown and chosen in the instrument's written pitch.
class TargetPicker extends ConsumerWidget {
  const TargetPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final drone = ref.watch(droneProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(droneProvider.notifier);
    final instrument = settings.instrument;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final frequency = NoteMapper(a4: settings.a4).frequencyOf(drone.note);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.lowerSemitone,
              onPressed: drone.midi > _minMidi
                  ? () => controller.setMidi(drone.midi - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const SafeArea(child: _TargetSheet()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        l10n.targetLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      Text(
                        instrument.writtenNote(drone.note).label,
                        key: const Key('targetNote'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          if (instrument.isTransposing)
                            l10n.concertValue(drone.note.label),
                          '${NumberFormat('0.0', locale).format(frequency)} Hz',
                        ].join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.raiseSemitone,
              onPressed: drone.midi < _maxMidi
                  ? () => controller.setMidi(drone.midi + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              key: const Key('targetPlay'),
              onPressed: controller.toggle,
              icon: Icon(drone.playing ? Icons.stop : Icons.volume_up),
              label: Text(drone.playing ? l10n.stop : l10n.play),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Note grid and octave stepper, in written pitch.
class _TargetSheet extends ConsumerWidget {
  const _TargetSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final drone = ref.watch(droneProvider);
    final Instrument instrument = ref.watch(settingsProvider).instrument;
    final controller = ref.read(droneProvider.notifier);
    final offset = instrument.writtenOffset;
    final written = instrument.writtenNote(drone.note);
    final octaveStart = (written.octave + 1) * 12;

    bool valid(int writtenMidi) {
      final concert = writtenMidi - offset;
      return concert >= _minMidi && concert <= _maxMidi;
    }

    void pick(int writtenMidi) => controller.setMidi(writtenMidi - offset);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.chooseTarget, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
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
                  selected: written.pitchClass == pc,
                  onPressed: valid(octaveStart + pc)
                      ? () => pick(octaveStart + pc)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: l10n.lowerOctave,
                onPressed: valid(written.midi - 12)
                    ? () => pick(written.midi - 12)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  l10n.droneOctave(written.octave),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.raiseOctave,
                onPressed: valid(written.midi + 12)
                    ? () => pick(written.midi + 12)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
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
  final VoidCallback? onPressed;

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
