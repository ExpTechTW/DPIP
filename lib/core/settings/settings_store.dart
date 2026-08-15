/// The only sanctioned gateway to persisted settings.
///
/// Every method is keyed by a [SettingKey], and **no overload accepts a raw
/// `String`**, so an ad-hoc key cannot reach storage — the compiler rejects
/// it, not review. `T` on the key must match the method, so a type-mismatched
/// read or write also fails to compile.
///
/// Backed by the `settings` table of the durable database (see
/// `core/storage/app_database.dart`), which is what makes it survive an OS
/// cache purge and keeps it out of reach of "clear cache".
///
/// **Reads are synchronous.** Settings are read during `build` all over the
/// app, and SQLite is not. So the whole table — a few dozen short rows — is
/// loaded into memory once at bootstrap and served from there; writes update
/// memory immediately and reach the database in the background. The trade is
/// deliberate and stated here rather than hidden inside a plugin.
///
/// A write that fails is logged, not thrown: a setting that did not persist is
/// worth a log line, never a crash in a settings screen.
library;

import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:sqflite/sqflite.dart';

/// The table this store owns. Named here so `app_database.dart` can document
/// the layout and the storage gate can check nothing else writes it.
const String settingsTable = 'settings';

final class SettingsStore {
  SettingsStore._(this._db, this._values);

  /// The database, or null when it could not be opened — the app then runs
  /// with settings that live only for this session rather than not at all.
  final Database? _db;

  /// The whole table, in memory.
  final Map<String, Object?> _values;

  /// Creates the table. Safe to call on every open.
  static Future<void> createSchema(Database db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $settingsTable ('
    'key TEXT PRIMARY KEY NOT NULL, '
    'value TEXT NOT NULL)',
  );

  /// Loads every row into memory.
  static Future<SettingsStore> open(Database? db) async {
    final values = <String, Object?>{};
    if (db != null) {
      try {
        for (final row in await db.query(settingsTable)) {
          final key = row['key'] as String?;
          final value = row['value'] as String?;
          if (key == null || value == null) continue;
          values[key] = jsonDecode(value);
        }
      } catch (error, stackTrace) {
        Log.handle(error, stackTrace, 'loading settings');
      }
    }
    return SettingsStore._(db, values);
  }

  /// An in-memory store with no database behind it — for tests, and for a
  /// launch where the database would not open.
  factory SettingsStore.inMemory([Map<String, Object?> initial = const {}]) =>
      SettingsStore._(null, {...initial});

  bool? getBool(SettingKey<bool> key) => _values[key.name] as bool?;
  Future<void> setBool(SettingKey<bool> key, bool value) => _put(key, value);

  int? getInt(SettingKey<int> key) => (_values[key.name] as num?)?.toInt();
  Future<void> setInt(SettingKey<int> key, int value) => _put(key, value);

  String? getString(SettingKey<String> key) => _values[key.name] as String?;
  Future<void> setString(SettingKey<String> key, String value) =>
      _put(key, value);

  List<String>? getStringList(SettingKey<List<String>> key) {
    final stored = _values[key.name];
    if (stored is! List) return null;
    return stored.cast<String>();
  }

  Future<void> setStringList(
    SettingKey<List<String>> key,
    List<String> value,
  ) => _put(key, value);

  /// Type-agnostic, so it takes any key via covariance
  /// (`SettingKey<bool> <: SettingKey<Object?>`).
  Future<void> remove(SettingKey<Object?> key) async {
    _values.remove(key.name);
    final db = _db;
    if (db == null) return;
    try {
      await db.delete(settingsTable, where: 'key = ?', whereArgs: [key.name]);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'removing setting ${key.name}');
    }
  }

  /// Every key currently stored — used by the migration to know when it is
  /// finished, and by the debug page.
  Iterable<String> get keys => _values.keys;

  Future<void> _put(SettingKey<Object?> key, Object value) async {
    _values[key.name] = value;
    final db = _db;
    if (db == null) return;
    try {
      await db.insert(settingsTable, {
        'key': key.name,
        'value': jsonEncode(value),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing setting ${key.name}');
    }
  }
}
