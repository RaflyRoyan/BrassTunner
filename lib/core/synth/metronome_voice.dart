import 'dart:math' as math;
import 'dart:typed_data';

/// A click that starts [frameOffset] frames into a rendered block.
class BeatEvent {
  const BeatEvent({required this.beatInBar, required this.frameOffset});

  /// 0 = first (accented) beat of the bar.
  final int beatInBar;
  final int frameOffset;
}

/// Sample-accurate metronome: clicks are rendered into the audio stream
/// rather than triggered by timers, so tempo never drifts or jitters.
class MetronomeVoice {
  MetronomeVoice(this.sampleRate)
    : _accentClick = _makeClick(sampleRate, 1760),
      _normalClick = _makeClick(sampleRate, 1175) {
    _framesPerBeat = _framesFor(_bpm);
  }

  static const int minBpm = 30;
  static const int maxBpm = 250;
  static const int maxBeatsPerBar = 12;

  final double sampleRate;
  final Float32List _accentClick;
  final Float32List _normalClick;

  /// Click level 0..1.
  double volume = 0.8;

  int _bpm = 100;
  int _beatsPerBar = 4;
  late double _framesPerBeat;

  bool _running = false;
  int _position = 0;
  double _nextBeat = 0;
  int _beat = 0;
  Float32List? _click;
  int _clickIndex = 0;

  bool get running => _running;

  /// True when stopped and the last click has finished.
  bool get isSilent => !_running && _click == null;

  int get bpm => _bpm;
  set bpm(int value) {
    final bpm = value.clamp(minBpm, maxBpm);
    if (bpm == _bpm) return;
    final previous = _framesPerBeat;
    _bpm = bpm;
    _framesPerBeat = _framesFor(bpm);
    if (_running) {
      // Keep the beat that already sounded; space the next one by the new
      // tempo (never in the past).
      final lastBeat = _nextBeat - previous;
      _nextBeat = math.max(lastBeat + _framesPerBeat, _position.toDouble());
    }
  }

  /// Beats per bar; 1 means no accent.
  int get beatsPerBar => _beatsPerBar;
  set beatsPerBar(int value) {
    _beatsPerBar = value.clamp(1, maxBeatsPerBar);
    _beat = 0; // next click starts a new bar
  }

  void start() {
    if (_running) return;
    _running = true;
    _position = 0;
    _nextBeat = 0;
    _beat = 0;
  }

  void stop() => _running = false;

  /// Mixes clicks into [buffer] and appends a [BeatEvent] for each click
  /// that starts in it.
  void addTo(Float32List buffer, List<BeatEvent> events) {
    if (isSilent) return;
    for (var i = 0; i < buffer.length; i++) {
      if (_running && _position >= _nextBeat) {
        final beatInBar = _beat % _beatsPerBar;
        _click = beatInBar == 0 && _beatsPerBar > 1
            ? _accentClick
            : _normalClick;
        _clickIndex = 0;
        events.add(BeatEvent(beatInBar: beatInBar, frameOffset: i));
        _beat++;
        _nextBeat += _framesPerBeat;
      }
      final click = _click;
      if (click != null) {
        buffer[i] += click[_clickIndex++] * volume;
        if (_clickIndex >= click.length) _click = null;
      }
      _position++;
    }
  }

  double _framesFor(int bpm) => sampleRate * 60 / bpm;

  /// Short decaying sine burst: 1 ms attack, ~6 ms decay, 30 ms total.
  static Float32List _makeClick(double sampleRate, double frequency) {
    final length = (0.03 * sampleRate).round();
    final attack = 0.001 * sampleRate;
    final out = Float32List(length);
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final envelope = math.min(1.0, i / attack) * math.exp(-t / 0.006) * 0.9;
      out[i] = envelope * math.sin(2 * math.pi * frequency * t);
    }
    return out;
  }
}
