import 'dart:typed_data';

import 'package:brass_tunner/core/pitch/pitch_tracker.dart';
import 'package:brass_tunner/core/pitch/pitch_worker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'signals.dart';

/// [seconds] of a sine as PCM16 bytes, split into 20 ms mic-like chunks.
List<Uint8List> pcmChunks(double frequency, {double seconds = 0.4}) {
  final samples = sine(frequency, length: (seconds * sampleRate).round());
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, (samples[i] * 32767).round(), Endian.little);
  }
  final bytes = data.buffer.asUint8List();
  const chunk = 1764; // 882 samples
  return [
    for (var i = 0; i < bytes.length; i += chunk)
      Uint8List.sublistView(
        bytes,
        i,
        i + chunk > bytes.length ? bytes.length : i + chunk,
      ),
  ];
}

void main() {
  late PitchWorker worker;

  setUp(() async => worker = await PitchWorker.spawn());
  tearDown(() => worker.dispose());

  Future<TunerReading> lastReadingFor(double frequency) async {
    final readings = <TunerReading?>[];
    final sub = worker.readings.listen(readings.add);
    pcmChunks(frequency).forEach(worker.addPcm16);
    // 0.4 s of audio: (17640 - 4096) / 1024 + 1 = 14 windows.
    await Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return readings.length < 14;
    }).timeout(const Duration(seconds: 5));
    await sub.cancel();
    return readings.last!;
  }

  test('detects pitch from PCM16 bytes in a background isolate', () async {
    final reading = await lastReadingFor(233.08);
    expect(reading.note.note.label, 'B♭3');
    expect(reading.note.cents.abs(), lessThan(1));
  });

  test('setA4 changes the reference used by the worker', () async {
    worker.setA4(442);
    final reading = await lastReadingFor(440);
    expect(reading.note.note.label, 'A4');
    expect(reading.note.cents, closeTo(-7.85, 1));
  });

  test('reset clears the reading', () async {
    await lastReadingFor(233.08);
    final next = worker.readings.first;
    worker.reset();
    expect(await next.timeout(const Duration(seconds: 2)), isNull);
  });
}
