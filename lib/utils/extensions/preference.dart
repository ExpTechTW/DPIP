import 'package:shared_preferences/shared_preferences.dart';

import 'package:dpip/utils/log.dart';

extension PreferenceExtension on SharedPreferencesWithCache {
  /// Sets a value of any supported type to SharedPreferences.
  ///
  /// This is a convenience method that automatically handles different types
  /// supported by SharedPreferences. It will call the appropriate type-specific
  /// setter method based on the type of [value].
  ///
  /// Supported types are:
  /// * [String]
  /// * [int]
  /// * [bool]
  /// * [double]
  /// * [List<String>]
  ///
  /// If [value] is null or omitted, the key will be removed from SharedPreferences.
  Future<void> set<T>(String key, [T? value]) {
    try {
      if (value == null) {
        return remove(key);
      }

      switch (value) {
        case String():
          return setString(key, value);
        case int():
          return setInt(key, value);
        case bool():
          return setBool(key, value);
        case double():
          return setDouble(key, value);
        case List<String>():
          return setStringList(key, value);
        default:
          throw ArgumentError.value(value, 'value', 'Unsupported type: ${value.runtimeType}');
      }
    } catch (e, s) {
      TalkerManager.instance.error('💾 $key set to "$value" FAILED', e, s);
      rethrow;
    } finally {
      TalkerManager.instance.info('💾 $key set to "$value"');
    }
  }
}
