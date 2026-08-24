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
/// A launch where the database would not open degrades to a **session-only**
/// store: reads answer what memory holds (nothing) and writes stay in memory.
/// Every such write is recorded in [_pendingWrites] and warned once, so a
/// degraded session is visible in the log and reversible — [attachDatabase]
/// replays those writes once a database is opened later in the same session
/// (see `_recoverDurable` in `bootstrap.dart`).
///
/// A write that fails is logged, not thrown: a setting that did not persist is
/// worth a log line, never a crash in a settings screen.
library;

import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// The table this store owns. Named here so `app_database.dart` can document
/// the layout and the storage gate can check nothing else writes it.
const String settingsTable = 'settings';

final class SettingsStore {
  SettingsStore._(this._db, this._values);

  static const int _loadAttempts = 3;

  /// The database, or null when it could not be opened — the app then runs
  /// with settings that live only for this session rather than not at all.
  SqliteDatabase? _db;

  /// The whole table, in memory.
  final Map<String, Object?> _values;

  /// Writes made while [_db] was null — the degraded-session backlog that
  /// [attachDatabase] replays. A removal is remembered as a removal (null
  /// value), so replaying cannot resurrect a deleted key.
  final Map<String, Object?> _pendingWrites = {};

  /// Creates the table. Safe to call on every open.
  static Future<void> createSchema(SqliteDatabase db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $settingsTable ('
    'key TEXT PRIMARY KEY NOT NULL, '
    'value TEXT NOT NULL)',
  );

  /// Loads every row into memory.
  static Future<SettingsStore> open(SqliteDatabase? db) async {
    if (db == null) return SettingsStore._(null, {});

    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= _loadAttempts; attempt++) {
      try {
        final values = <String, Object?>{};
        for (final row in await db.getAll(
          'SELECT key, value FROM $settingsTable',
        )) {
          final key = row['key'] as String?;
          final value = row['value'] as String?;
          if (key == null || value == null) continue;
          try {
            values[key] = jsonDecode(value);
          } catch (error, stackTrace) {
            // One damaged setting must not discard every row that follows it.
            // In particular, losing `onboarding.complete` turns a returning
            // installation into an apparent first launch.
            Log.handle(error, stackTrace, 'loading setting $key');
          }
        }
        if (attempt > 1) {
          Log.info(
            'settings recovered on read attempt $attempt/$_loadAttempts',
          );
        }
        return SettingsStore._(db, values);
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        if (attempt < _loadAttempts) {
          Log.warning(
            'settings read attempt $attempt/$_loadAttempts failed; retrying',
          );
          await Future<void>.delayed(Duration(milliseconds: 75 * attempt));
        }
      }
    }

    Log.handle(lastError!, lastStackTrace, 'loading settings');
    return SettingsStore._(db, {});
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
    if (db == null) {
      _pendingWrites[key.name] = null;
      return;
    }
    try {
      await db.execute('DELETE FROM $settingsTable WHERE key = ?', [key.name]);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'removing setting ${key.name}');
    }
  }

  /// Every key currently stored — used by the migration to know when it is
  /// finished, and by the debug page.
  Iterable<String> get keys => _values.keys;

  /// Whether this session is running without a database — reads still work,
  /// but nothing written here survives the process.
  bool get isDegraded => _db == null;

  /// Binds a database to a store that launched without one, and reconciles
  /// the two directions:
  ///
  /// 1. **Session → disk**: writes made while degraded are replayed, removals
  ///    included, so what the user did this session survives.
  /// 2. **Disk → session**: rows the session never saw (the whole table, for
  ///    a launch whose open failed) are adopted into memory — *only* keys
  ///    memory has no opinion on, never overwriting what the session read or
  ///    wrote. This is what un-degrades the launch: `onboarding.complete`,
  ///    saved regions and the push token come back instead of the session
  ///    spending its whole life looking like a first run.
  ///
  /// Returns whether anything moved in either direction. Attaching to an
  /// already-attached store is a no-op that answers false. A reconciliation
  /// failure leaves the store degraded and throws, so the caller can close the
  /// failed handle and retry without losing the backlog.
  Future<bool> attachDatabase(SqliteDatabase db) async {
    if (_db != null) return false;
    var moved = false;
    // Adopt disk first, without overwriting anything this session has already
    // read or written. A write racing this await updates [_values] immediately,
    // so the containsKey check still gives the session the final say.
    for (final row in await db.getAll(
      'SELECT key, value FROM $settingsTable',
    )) {
      final name = row['key'] as String?;
      final raw = row['value'] as String?;
      if (name == null ||
          raw == null ||
          _values.containsKey(name) ||
          _pendingWrites.containsKey(name)) {
        continue;
      }
      try {
        _values[name] = jsonDecode(raw);
        moved = true;
      } catch (_) {
        // A row unreadable at attach time is no better than one unreadable at
        // load time — skip it rather than poison the session.
      }
    }

    // Drain until empty. Writes keep using [_pendingWrites] while [_db] is
    // null; checking empty and publishing [_db] contain no await between them,
    // so no write can land in an orphaned queue at the hand-off boundary.
    while (true) {
      final pending = Map<String, Object?>.of(_pendingWrites);
      if (pending.isEmpty) {
        _db = db;
        return moved;
      }
      _pendingWrites.clear();
      try {
        await db.writeTransaction((tx) async {
          for (final MapEntry(key: name, :value) in pending.entries) {
            if (value == null) {
              await tx.execute('DELETE FROM $settingsTable WHERE key = ?', [
                name,
              ]);
            } else {
              await tx.execute(
                'INSERT OR REPLACE INTO $settingsTable (key, value) '
                'VALUES (?, ?)',
                [name, jsonEncode(value)],
              );
            }
          }
        });
        moved = true;
      } catch (error, stackTrace) {
        // A newer racing write for the same key wins; otherwise restore the
        // failed batch intact for the next recovery attempt.
        for (final entry in pending.entries) {
          if (!_pendingWrites.containsKey(entry.key)) {
            _pendingWrites[entry.key] = entry.value;
          }
        }
        Log.handle(error, stackTrace, 'attaching durable settings database');
        rethrow;
      }
    }
  }

  Future<void> _put(SettingKey<Object?> key, Object value) async {
    _values[key.name] = value;
    final db = _db;
    if (db == null) {
      // A degraded session must not look healthy: without this line a launch
      // whose database never opened runs, accepts every setting, and drops
      // all of them silently — the "configured install looks like first run"
      // bug wearing a different hat.
      if (_pendingWrites.isEmpty) {
        Log.warning(
          'settings are session-only: the durable database is not open',
        );
      }
      _pendingWrites[key.name] = value;
      return;
    }
    try {
      await db.execute(
        'INSERT OR REPLACE INTO $settingsTable (key, value) VALUES (?, ?)',
        [key.name, jsonEncode(value)],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing setting ${key.name}');
    }
  }
}
