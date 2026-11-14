import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/platform/clock.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/application/tuner_controller.dart';
import '../../tuner/domain/instrument.dart';
import '../data/session_repository.dart';
import '../domain/practice_session.dart';
import '../domain/session_recorder.dart';

export '../../../shared/platform/clock.dart' show clockProvider;

/// Must be overridden in `main` with a repository opened before `runApp`.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw UnimplementedError('sessionRepositoryProvider not overridden'),
);

/// Saved sessions, newest first; null lists every instrument.
final historyProvider =
    FutureProvider.family<List<PracticeSession>, Instrument?>(
      (ref, instrument) =>
          ref.watch(sessionRepositoryProvider).list(instrument: instrument),
    );

/// Records practice in the background whenever the mic is listening and
/// saves each finished session. State counts saved sessions.
///
/// A session ends when the mic stops (tab change, app hidden), after a long
/// silence, or when the instrument or A4 changes.
final sessionRecorderProvider =
    NotifierProvider<SessionRecorderController, int>(
      SessionRecorderController.new,
    );

class SessionRecorderController extends Notifier<int> {
  late SessionRecorder _recorder;

  @override
  int build() {
    final settings = ref.read(settingsProvider);
    _recorder = SessionRecorder(
      instrument: settings.instrument,
      a4: settings.a4,
    );
    final repository = ref.read(sessionRepositoryProvider);

    ref.listen(settingsProvider, (_, next) {
      _close(repository);
      _recorder = SessionRecorder(instrument: next.instrument, a4: next.a4);
    });
    ref.listen(tunerControllerProvider, (_, tuner) {
      if (tuner.status != TunerStatus.listening) {
        _close(repository);
        return;
      }
      final closed = _recorder.add(ref.read(clockProvider)(), tuner.reading);
      if (closed != null) _save(repository, closed);
    });
    ref.onDispose(() => _close(repository));
    return 0;
  }

  void _close(SessionRepository repository) {
    final session = _recorder.finish();
    if (session != null) _save(repository, session);
  }

  void _save(SessionRepository repository, PracticeSession session) {
    unawaited(
      repository
          .insert(session)
          .then(
            (_) {
              if (!ref.mounted) return;
              ref.invalidate(historyProvider);
              state++;
            },
            onError: (Object e) {
              // A lost session is not worth interrupting practice for.
              debugPrint('Saving practice session failed: $e');
            },
          ),
    );
  }
}

/// Deletes saved sessions and refreshes the lists.
final historyActionsProvider = Provider<HistoryActions>(HistoryActions.new);

class HistoryActions {
  HistoryActions(this._ref);

  final Ref _ref;

  Future<void> delete(int id) async {
    await _ref.read(sessionRepositoryProvider).delete(id);
    _ref.invalidate(historyProvider);
  }

  Future<void> clear() async {
    await _ref.read(sessionRepositoryProvider).clear();
    _ref.invalidate(historyProvider);
  }
}
