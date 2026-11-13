import 'dart:typed_data';

import 'package:brass_tunner/core/pitch/noise_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'signals.dart';

void main() {
  test('rmsDb of a full-scale sine is about -3 dBFS', () {
    expect(NoiseGate.rmsDb(sine(440, amplitude: 1)), closeTo(-3.01, 0.05));
  });

  test('rmsDb of silence is negative infinity', () {
    expect(NoiseGate.rmsDb(Float32List(4096)), double.negativeInfinity);
    expect(NoiseGate.rmsDb(const []), double.negativeInfinity);
  });

  test('stays closed for quiet signals', () {
    final gate = NoiseGate();
    expect(gate.process(sine(440, amplitude: 0.001)), isFalse); // ≈ -63 dBFS
  });

  test('opens for loud signals', () {
    final gate = NoiseGate();
    expect(gate.process(sine(440, amplitude: 0.1)), isTrue); // ≈ -23 dBFS
  });

  test('hysteresis: level between thresholds keeps the current state', () {
    final gate = NoiseGate(openThresholdDb: -45, closeThresholdDb: -50);
    final between = sine(440, amplitude: 0.0063); // ≈ -47 dBFS

    expect(gate.process(between), isFalse, reason: 'not yet opened');
    gate.process(sine(440, amplitude: 0.1));
    expect(gate.process(between), isTrue, reason: 'stays open while decaying');
    expect(gate.process(sine(440, amplitude: 0.001)), isFalse);
  });

  test('reports the level of the last frame', () {
    final gate = NoiseGate()..process(sine(440, amplitude: 0.1));
    expect(gate.lastLevelDb, closeTo(-23.01, 0.05));
  });

  test('rejects a close threshold above the open threshold', () {
    expect(
      () => NoiseGate(openThresholdDb: -50, closeThresholdDb: -40),
      throwsArgumentError,
    );
  });
}
