import '../../../core/pitch/pitch_tracker.dart';
import '../../tuner/domain/instrument.dart';
import 'practice_session.dart';

/// Turns a stream of tuner readings into [PracticeSession]s.
///
/// Only notes held for [settle] are counted, so attacks and passing notes
/// do not skew the averages. A silence longer than [maxGap] ends the
/// session; sessions with less than [minPlayed] of counted playing are
/// dropped as noise.
class SessionRecorder {
  SessionRecorder({
    required this.instrument,
    required this.a4,
    this.settle = const Duration(milliseconds: 150),
    this.maxGap = const Duration(minutes: 2),
    this.minPlayed = const Duration(seconds: 10),
    this.frameDuration = const Duration(microseconds: 23220), // 1024 / 44.1k
  });

  final Instrument instrument;
  final double a4;
  final Duration settle;
  final Duration maxGap;
  final Duration minPlayed;

  /// Time one tuner frame stands for, to turn sample counts into played
  /// time.
  final Duration frameDuration;

  DateTime? _first;
  DateTime? _last;
  int? _heldMidi;
  DateTime? _heldSince;
  final _notes = <int, _Accumulator>{};

  bool get isRecording => _first != null;

  /// Feeds a reading taken at [now]. Returns a finished session when a long
  /// silence closed the previous one.
  PracticeSession? add(DateTime now, TunerReading? reading) {
    PracticeSession? closed;
    final last = _last;
    if (last != null && now.difference(last) > maxGap) closed = finish();

    if (reading == null) {
      _heldMidi = null;
      return closed;
    }
    final midi = reading.note.note.midi;
    if (midi != _heldMidi) {
      _heldMidi = midi;
      _heldSince = now;
    }
    if (now.difference(_heldSince!) < settle) return closed;

    _first ??= now;
    _last = now;
    (_notes[midi] ??= _Accumulator()).add(reading.note.cents);
    return closed;
  }

  /// Ends the current session. Returns it, or null when too little was
  /// played.
  PracticeSession? finish() {
    final first = _first;
    final last = _last;
    final notes = (_notes.keys.toList()..sort())
        .map((m) => _notes[m]!.toStat(m))
        .toList();
    _first = null;
    _last = null;
    _heldMidi = null;
    _notes.clear();

    if (first == null || last == null) return null;
    final samples = notes.fold(0, (sum, n) => sum + n.samples);
    if (frameDuration * samples < minPlayed) return null;
    return PracticeSession(
      startedAt: first,
      duration: last.difference(first),
      instrument: instrument,
      a4: a4,
      notes: notes,
    );
  }
}

class _Accumulator {
  int samples = 0;
  double sum = 0;
  int sharp = 0;
  int flat = 0;

  void add(double cents) {
    samples++;
    sum += cents;
    if (cents > NoteStat.toleranceCents) sharp++;
    if (cents < -NoteStat.toleranceCents) flat++;
  }

  NoteStat toStat(int midi) => NoteStat(
    midi: midi,
    samples: samples,
    meanCents: sum / samples,
    sharp: sharp,
    flat: flat,
  );
}
