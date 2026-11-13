import 'dart:typed_data';

/// Decodes little-endian signed 16-bit PCM bytes into floats in -1..1.
///
/// Mic chunks are not guaranteed to hold a whole number of samples, so a
/// trailing odd byte is carried over to the next call.
class Pcm16Decoder {
  int? _carry;

  Float32List convert(Uint8List bytes) {
    final carry = _carry;
    final total = bytes.length + (carry == null ? 0 : 1);
    final out = Float32List(total ~/ 2);
    var i = 0;
    var o = 0;
    if (carry != null && bytes.isNotEmpty) {
      out[o++] = (carry | (bytes[0] << 8)).toSigned(16) / 32768;
      i = 1;
      _carry = null;
    }
    for (; i + 1 < bytes.length; i += 2) {
      out[o++] = (bytes[i] | (bytes[i + 1] << 8)).toSigned(16) / 32768;
    }
    if (i < bytes.length) _carry = bytes[i];
    return out;
  }

  void reset() => _carry = null;
}
