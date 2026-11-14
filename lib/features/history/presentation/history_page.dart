import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/domain/instrument.dart';
import '../../tuner/domain/tuning_zone.dart';
import '../../tuner/presentation/instrument_l10n.dart';
import '../application/history_controller.dart';
import '../domain/practice_session.dart';
import '../domain/practice_stats.dart';

/// Saved sessions for one instrument plus the notes that most often run
/// sharp or flat. Notes are shown as the player reads them.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late Instrument _instrument = ref.read(settingsProvider).instrument;

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(historyActionsProvider).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(historyProvider(_instrument));
    final sessions = history.value ?? const <PracticeSession>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          if (sessions.isNotEmpty)
            IconButton(
              tooltip: l10n.deleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButton<Instrument>(
              key: const Key('historyInstrument'),
              value: _instrument,
              isExpanded: true,
              items: [
                for (final i in Instrument.values)
                  DropdownMenuItem(value: i, child: Text(i.nameWithKey(l10n))),
              ],
              onChanged: (i) => setState(() => _instrument = i!),
            ),
            const SizedBox(height: 16),
            ...switch (history) {
              AsyncError() => [Text(l10n.historyLoadError)],
              AsyncData(value: final s) when s.isEmpty => [
                Text(
                  l10n.historyEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              AsyncData(value: final s) => _content(context, s),
              _ => [const Center(child: CircularProgressIndicator())],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<PracticeSession> sessions) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final stats = PracticeStats(sessions);
    final oneDecimal = NumberFormat('0.0', locale);

    return [
      Row(
        children: [
          _Stat(label: l10n.statSessions, value: '${stats.sessionCount}'),
          _Stat(
            label: l10n.statTotalTime,
            value: formatDuration(l10n, stats.totalDuration),
          ),
          _Stat(
            label: l10n.statMeanDeviation,
            value: '±${oneDecimal.format(stats.meanAbsCents)}¢',
            color: tuningZoneColor(
              TuningZone.of(stats.meanAbsCents),
              theme.brightness,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _TendencyCard(
        key: const Key('mostSharp'),
        title: l10n.mostSharpTitle,
        icon: Icons.arrow_upward,
        notes: stats.mostSharp(),
        instrument: _instrument,
        sharp: true,
      ),
      const SizedBox(height: 12),
      _TendencyCard(
        key: const Key('mostFlat'),
        title: l10n.mostFlatTitle,
        icon: Icons.arrow_downward,
        notes: stats.mostFlat(),
        instrument: _instrument,
        sharp: false,
      ),
      const SizedBox(height: 24),
      Text(l10n.sessionsTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      for (final s in sessions) _SessionTile(session: s),
    ];
  }
}

String formatDuration(AppLocalizations l10n, Duration d) {
  final hours = d.inHours;
  if (hours > 0) return l10n.durationHours(hours, d.inMinutes % 60);
  return l10n.durationMinutes(d.inMinutes, d.inSeconds % 60);
}

String signedCents(double cents) {
  final r = cents.round();
  // U+2212 minus sign lines up with the plus sign.
  return '${r > 0
      ? '+'
      : r < 0
      ? '−'
      : ''}${r.abs()}¢';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TendencyCard extends StatelessWidget {
  const _TendencyCard({
    super.key,
    required this.title,
    required this.icon,
    required this.notes,
    required this.instrument,
    required this.sharp,
  });

  final String title;
  final IconData icon;
  final List<NoteStat> notes;
  final Instrument instrument;
  final bool sharp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              Text(
                l10n.notEnoughData,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        instrument.writtenNote(Note(n.midi)).label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        sharp
                            ? l10n.sharpShare(
                                percent.format(n.sharpRatio),
                                signedCents(n.meanCents),
                              )
                            : l10n.flatShare(
                                percent.format(n.flatRatio),
                                signedCents(n.meanCents),
                              ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tuningZoneColor(
                            TuningZone.of(n.meanCents),
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final percent = NumberFormat.percentPattern(locale);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ExpansionTile(
      key: ValueKey('session-${session.id}'),
      tilePadding: EdgeInsets.zero,
      title: Text(DateFormat.yMMMd(locale).add_Hm().format(session.startedAt)),
      subtitle: Text(
        l10n.sessionSummary(
          formatDuration(l10n, session.duration),
          NumberFormat('0.0', locale).format(session.meanAbsCents),
          session.notes.length,
        ),
      ),
      children: [
        for (final n in session.notes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    session.instrument.writtenNote(Note(n.midi)).label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    signedCents(n.meanCents),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tuningZoneColor(
                        TuningZone.of(n.meanCents),
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '▲ ${percent.format(n.sharpRatio)}  '
                    '▼ ${percent.format(n.flatRatio)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                ref.read(historyActionsProvider).delete(session.id!),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteSession),
          ),
        ),
      ],
    );
  }
}
