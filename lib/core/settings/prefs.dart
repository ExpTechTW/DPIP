/// The only sanctioned gateway to `SharedPreferences`.
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A typed wrapper over [SharedPreferences]: every method is keyed by a
/// [PrefKey], and **no overload accepts a raw `String`**, so an ad-hoc key
/// cannot reach storage — the compiler rejects it. `T` on the key must match the
/// method (`getBool` takes `PrefKey<bool>`, etc.), so a type-mismatched
/// read/write also fails to compile.
///
/// Stores receive a [Prefs], never a bare [SharedPreferences]. Only this file
/// and `bootstrap.dart` may import `shared_preferences` (enforced by
/// `tool/check_prefs.sh`); the single instance is minted once in `bootstrap()`.
final class Prefs {
  const Prefs(this._prefs);

  final SharedPreferences _prefs;

  bool? getBool(PrefKey<bool> key) => _prefs.getBool(key.name);
  Future<bool> setBool(PrefKey<bool> key, bool value) =>
      _prefs.setBool(key.name, value);

  int? getInt(PrefKey<int> key) => _prefs.getInt(key.name);
  Future<bool> setInt(PrefKey<int> key, int value) =>
      _prefs.setInt(key.name, value);

  String? getString(PrefKey<String> key) => _prefs.getString(key.name);
  Future<bool> setString(PrefKey<String> key, String value) =>
      _prefs.setString(key.name, value);

  List<String>? getStringList(PrefKey<List<String>> key) =>
      _prefs.getStringList(key.name);
  Future<bool> setStringList(PrefKey<List<String>> key, List<String> value) =>
      _prefs.setStringList(key.name, value);

  /// Type-agnostic, so it takes any key via covariance
  /// (`PrefKey<bool> <: PrefKey<Object?>`).
  Future<bool> remove(PrefKey<Object?> key) => _prefs.remove(key.name);
}
