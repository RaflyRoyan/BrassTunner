import 'package:shared_preferences/shared_preferences.dart';

/// Minimal persistence interface so settings logic can be tested without
/// platform channels.
abstract interface class KeyValueStore {
  double? getDouble(String key);
  int? getInt(String key);
  String? getString(String key);
  Future<void> setDouble(String key, double value);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  /// Opens the store with an allow-list of the keys the app uses.
  static Future<SharedPreferencesStore> open(Set<String> keys) async =>
      SharedPreferencesStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: SharedPreferencesWithCacheOptions(allowList: keys),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  double? getDouble(String key) => _prefs.getDouble(key);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
