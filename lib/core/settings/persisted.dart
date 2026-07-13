import 'package:shared_preferences/shared_preferences.dart';

/// A single enum setting backed by [SharedPreferences] — reads with a fallback
/// on construction and persists on change.
///
/// A plain value holder, deliberately NOT a `ChangeNotifier`: [set] returns
/// whether the value actually changed, so the owning settings object keeps
/// deciding when to `notifyListeners()` (the app's provider convention). Pass
/// [encode] when the enum persists as something other than its `name` (e.g. a
/// region `.code`) — typed, so no `as dynamic` casts leak in.
class PersistedEnum<T extends Enum> {
  PersistedEnum(
    this._prefs, {
    required String key,
    required List<T> values,
    required T fallback,
    String Function(T value)? encode,
  }) : _key = key,
       _encode = encode ?? _name,
       _value = _read(_prefs, key, values, fallback, encode ?? _name);

  final SharedPreferences _prefs;
  final String _key;
  final String Function(T value) _encode;
  T _value;

  /// The current value.
  T get value => _value;

  /// Persists [next]; returns whether it changed, so the owner notifies only on
  /// a real change.
  bool set(T next) {
    if (next == _value) return false;
    _value = next;
    _prefs.setString(_key, _encode(next));
    return true;
  }

  static String _name(Enum value) => value.name;

  static T _read<T extends Enum>(
    SharedPreferences prefs,
    String key,
    List<T> values,
    T fallback,
    String Function(T value) encode,
  ) {
    final stored = prefs.getString(key);
    for (final value in values) {
      if (encode(value) == stored) return value;
    }
    return fallback;
  }
}
