import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../tuner/domain/instrument.dart';
import '../data/key_value_store.dart';

class TunerSettings {
  const TunerSettings({this.a4 = 440, this.instrument = Instrument.trumpet});

  final double a4;
  final Instrument instrument;

  TunerSettings copyWith({double? a4, Instrument? instrument}) => TunerSettings(
    a4: a4 ?? this.a4,
    instrument: instrument ?? this.instrument,
  );

  @override
  bool operator ==(Object other) =>
      other is TunerSettings &&
      other.a4 == a4 &&
      other.instrument == instrument;

  @override
  int get hashCode => Object.hash(a4, instrument);
}

/// Must be overridden in `main` with a store opened before `runApp`.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('keyValueStoreProvider not overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, TunerSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<TunerSettings> {
  static const a4Key = 'a4';
  static const instrumentKey = 'instrument';
  static const keys = {a4Key, instrumentKey};

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  TunerSettings build() {
    const defaults = TunerSettings();
    final storedA4 = _store.getDouble(a4Key);
    final storedInstrument = _store.getString(instrumentKey);
    return TunerSettings(
      a4: storedA4 != null && _validA4(storedA4) ? storedA4 : defaults.a4,
      instrument:
          Instrument.values.asNameMap()[storedInstrument] ??
          defaults.instrument,
    );
  }

  /// Sets A4, rounded to whole Hz and clamped to 430–450 Hz.
  Future<void> setA4(double a4) async {
    final value = a4
        .roundToDouble()
        .clamp(NoteMapper.minA4, NoteMapper.maxA4)
        .toDouble();
    if (value == state.a4) return;
    state = state.copyWith(a4: value);
    await _store.setDouble(a4Key, value);
  }

  Future<void> setInstrument(Instrument instrument) async {
    if (instrument == state.instrument) return;
    state = state.copyWith(instrument: instrument);
    await _store.setString(instrumentKey, instrument.name);
  }

  static bool _validA4(double a4) =>
      a4 >= NoteMapper.minA4 && a4 <= NoteMapper.maxA4;
}
