import 'dart:typed_data';

/// Turns a stream of arbitrarily sized audio chunks into overlapping
/// analysis windows of [windowSize] samples, one every [hopSize] samples.
///
/// With the defaults (4096 / 1024 at 44.1 kHz) a new window arrives every
/// ~23 ms while each window still spans ~93 ms, long enough for ~30 Hz.
class SlidingWindow {
  SlidingWindow({this.windowSize = 4096, this.hopSize = 1024})
    : _window = Float32List(windowSize) {
    if (hopSize < 1 || hopSize > windowSize) {
      throw ArgumentError.value(hopSize, 'hopSize', 'must be in 1..windowSize');
    }
  }

  final int windowSize;
  final int hopSize;

  final Float32List _window;

  /// Samples written into the window so far (saturates at [windowSize]).
  int _filled = 0;

  /// New samples since the last emitted window.
  int _sinceEmit = 0;

  /// Appends [samples] and calls [onWindow] for every completed window.
  ///
  /// The list passed to [onWindow] is reused; copy it if it must outlive the
  /// callback.
  void add(List<double> samples, void Function(Float32List window) onWindow) {
    var offset = 0;
    while (offset < samples.length) {
      if (_filled < windowSize) {
        final take = _min(samples.length - offset, windowSize - _filled);
        _window.setRange(_filled, _filled + take, samples, offset);
        _filled += take;
        _sinceEmit += take;
        offset += take;
      } else {
        // Window is full: slide left by the samples still needed for a hop.
        final take = _min(samples.length - offset, hopSize - _sinceEmit);
        _window.setRange(0, windowSize - take, _window, take);
        _window.setRange(windowSize - take, windowSize, samples, offset);
        _sinceEmit += take;
        offset += take;
      }
      if (_filled == windowSize && _sinceEmit >= hopSize) {
        _sinceEmit = 0;
        onWindow(_window);
      }
    }
  }

  void reset() {
    _filled = 0;
    _sinceEmit = 0;
  }

  static int _min(int a, int b) => a < b ? a : b;
}
