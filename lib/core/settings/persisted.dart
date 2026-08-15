import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// A single enum setting backed by [SettingsStore] — reads with a fallback on
/// construction and persists on change.
///
/// A plain value holder, deliberately NOT a `ChangeNotifier`: [set] returns
/// whether the value actually changed, so the owning settings object keeps
/// deciding when to `notifyListeners()`. Pass [encode] when the enum persists as
/// something other than its `name` (e.g. a region `.code`).
class PersistedEnum<T extends Enum> {
  PersistedEnum(
    this._settings, {
    required SettingKey<String> key,
    required List<T> values,
    required T fallback,
    String Function(T value)? encode,
  }) : _key = key,
       _encode = encode ?? _name,
       _value = _read(_settings, key, values, fallback, encode ?? _name);

  final SettingsStore _settings;
  final SettingKey<String> _key;
  final String Function(T value) _encode;
  T _value;

  /// The current value.
  T get value => _value;

  /// Persists [next]; returns whether it changed, so the owner notifies only on
  /// a real change.
  bool set(T next) {
    if (next == _value) return false;
    _value = next;
    _settings.setString(_key, _encode(next));
    return true;
  }

  static String _name(Enum value) => value.name;

  static T _read<T extends Enum>(
    SettingsStore settings,
    SettingKey<String> key,
    List<T> values,
    T fallback,
    String Function(T value) encode,
  ) {
    final stored = settings.getString(key);
    for (final value in values) {
      if (encode(value) == stored) return value;
    }
    return fallback;
  }
}
