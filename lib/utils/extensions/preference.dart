import 'package:shared_preferences/shared_preferences.dart';

import 'package:dpip/utils/log.dart';

/// Extension on [SharedPreferencesWithCache] that provides convenient utilities for preference storage.
///
/// This extension adds helpful methods to simplify storing and managing preferences, including type-safe value storage
/// with automatic type handling and logging.
extension PreferenceExtension on SharedPreferencesWithCache {
  /// Sets a value of any supported type to SharedPreferences.
  ///
  /// This is a convenience method that automatically handles different types supported by SharedPreferences. It calls
  /// the appropriate type-specific setter method based on the runtime type of [value].
  ///
  /// Supported types are: [String], [int], [bool], [double], and [List<String>]. If [value] is `null` or omitted, the
  /// key will be removed from SharedPreferences.
  ///
  /// All operations are logged for debugging purposes. If an error occurs, it is logged and rethrown.
  ///
  /// Throws [ArgumentError] if [value] is of an unsupported type.
  ///
  /// Example:
  /// ```dart
  /// // Store a string value
  /// await preferences.set('username', 'John');
  ///
  /// // Store an integer value
  /// await preferences.set('age', 25);
  ///
  /// // Store a boolean value
  /// await preferences.set('isEnabled', true);
  ///
  /// // Remove a key by passing null
  /// await preferences.set('username', null);
  /// ```
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
