import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while the tuner listens, so the player does not have
/// to touch the phone between notes.
abstract interface class ScreenWakeLock {
  Future<void> setEnabled(bool enabled);
}

class WakelockPlusScreenWakeLock implements ScreenWakeLock {
  bool? _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (e) {
      // Not fatal: the screen just times out as usual.
      debugPrint('Wake lock failed: $e');
    }
  }
}

final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => WakelockPlusScreenWakeLock(),
);
