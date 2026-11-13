import 'dart:typed_data';

import 'package:brass_tunner/core/audio/pcm_convert.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pcm(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('decodes signed little-endian 16-bit samples to -1..1', () {
    final out = Pcm16Decoder().convert(pcm([0, 16384, -16384, 32767, -32768]));
    expect(out, [0, 0.5, -0.5, closeTo(1, 1e-4), -1]);
  });

  test('carries an odd trailing byte into the next chunk', () {
    final bytes = pcm([1000, -2000, 3000]);
    final decoder = Pcm16Decoder();
    final a = decoder.convert(Uint8List.sublistView(bytes, 0, 3));
    final b = decoder.convert(Uint8List.sublistView(bytes, 3));
    expect([...a, ...b], Pcm16Decoder().convert(bytes));
    expect(a.length, 1);
    expect(b.length, 2);
  });

  test('single-byte chunks still decode correctly', () {
    final bytes = pcm([123, -456, 789]);
    final decoder = Pcm16Decoder();
    final out = [
      for (final byte in bytes) ...decoder.convert(Uint8List.fromList([byte])),
    ];
    expect(out, Pcm16Decoder().convert(bytes));
  });

  test('reset drops a pending byte', () {
    final decoder = Pcm16Decoder()..convert(Uint8List.fromList([0xFF]));
    decoder.reset();
    expect(decoder.convert(pcm([100])), [100 / 32768]);
  });
}
