import 'dart:typed_data';

import 'package:record/record.dart';

/// Microphone as a stream of raw mono PCM16 little-endian bytes.
class MicSource {
  MicSource({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const int sampleRate = 44100;

  final AudioRecorder _recorder;

  /// Asks for the microphone permission if needed. Returns whether granted.
  Future<bool> requestPermission() => _recorder.hasPermission();

  Future<Stream<Uint8List>> start() => _recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      // Any processing (gain riding, noise suppression) distorts the
      // waveform the pitch detector relies on.
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
      androidConfig: AndroidRecordConfig(
        // Android's CDD requires this source to have AGC and noise
        // reduction off; `unprocessed` is cleaner but not on every device.
        audioSource: AndroidAudioSource.voiceRecognition,
        // Bluetooth SCO would force 8–16 kHz telephone audio.
        manageBluetooth: false,
      ),
    ),
  );

  Future<void> stop() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  Future<void> dispose() => _recorder.dispose();
}
