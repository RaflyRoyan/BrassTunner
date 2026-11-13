import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/pitch/pitch_tracker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/ui/practice_quick_controls.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/instrument_list.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/tuner_controller.dart';
import '../domain/instrument.dart';
import '../domain/tuning_zone.dart';
import 'cents_meter.dart';
import 'instrument_l10n.dart';

/// Tuner tab. The mic itself is started and stopped by the home shell.
class TunerPage extends ConsumerWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuner = ref.watch(tunerControllerProvider);
    return MicGate(
      status: tuner.status,
      child: _TunerView(
        reading: tuner.reading,
        starting: tuner.status != TunerStatus.listening,
      ),
    );
  }
}

/// Shows [child] unless the mic is unavailable, in which case it explains
/// why and offers a retry.
class MicGate extends ConsumerWidget {
  const MicGate({super.key, required this.status, required this.child});

  final TunerStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tuner = ref.read(tunerControllerProvider.notifier);
    return switch (status) {
      TunerStatus.permissionDenied => _Problem(
        icon: Icons.mic_off_outlined,
        title: l10n.micPermissionDenied,
        message: l10n.micPermissionHint,
        onRetry: tuner.start,
      ),
      TunerStatus.error => _Problem(
        icon: Icons.error_outline,
        title: l10n.micError,
        onRetry: tuner.start,
      ),
      _ => child,
    };
  }
}

class _TunerView extends ConsumerWidget {
  const _TunerView({required this.reading, required this.starting});

  final TunerReading? reading;
  final bool starting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final reading = this.reading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          ActionChip(
            avatar: const Icon(Icons.music_note_outlined),
            label: Text(settings.instrument.nameWithKey(l10n)),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (sheetContext) => SafeArea(
                child: SingleChildScrollView(
                  child: InstrumentList(
                    onSelected: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: reading == null
                  ? _Waiting(text: starting ? l10n.startingMic : l10n.playANote)
                  : _NoteDisplay(
                      reading: reading,
                      instrument: settings.instrument,
                    ),
            ),
          ),
          CentsMeter(cents: reading?.note.cents),
          const SizedBox(height: 12),
          Text(
            reading == null
                ? '– Hz'
                : '${NumberFormat('0.0', locale).format(reading.note.frequency)} Hz',
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                child: Text(
                  l10n.a4Value(NumberFormat('0.#', locale).format(settings.a4)),
                ),
              ),
              const Spacer(),
              // Lets the metronome and drone run alongside the tuner.
              const PracticeQuickControls(),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({required this.reading, required this.instrument});

  final TunerReading reading;
  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final concert = reading.note.note;
    final shown = instrument.writtenNote(concert);
    final cents = reading.note.cents;
    final rounded = cents.round();
    final zoneColor = tuningZoneColor(TuningZone.of(cents), theme.brightness);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed-height slot so the note does not jump when switching
        // between transposing and concert instruments.
        SizedBox(
          height: 24,
          child: instrument.isTransposing
              ? Text(
                  '${l10n.writtenLabel} (${instrument.key.label})',
                  style: theme.textTheme.labelLarge?.copyWith(color: muted),
                )
              : null,
        ),
        Text.rich(
          TextSpan(
            text: shown.name,
            children: [
              TextSpan(
                text: '${shown.octave}',
                style: theme.textTheme.displaySmall?.copyWith(color: muted),
              ),
            ],
          ),
          key: const Key('noteName'),
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 112,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        SizedBox(
          height: 24,
          child: instrument.isTransposing
              ? Text(
                  l10n.concertValue(concert.label),
                  style: theme.textTheme.titleMedium?.copyWith(color: muted),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          // U+2212 minus sign lines up with the plus sign.
          '${rounded > 0
              ? '+'
              : rounded < 0
              ? '−'
              : ''}${rounded.abs()}¢',
          key: const Key('cents'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: zoneColor,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '–',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 112,
            color: muted,
          ),
        ),
        Text(text, style: theme.textTheme.titleMedium?.copyWith(color: muted)),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.icon,
    required this.title,
    required this.onRetry,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
