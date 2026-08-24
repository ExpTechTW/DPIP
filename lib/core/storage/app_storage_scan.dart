/// Sandbox disk-usage scan: what is actually on disk, where, and why.
///
/// iOS Settings reports the whole sandbox, which is routinely far larger than
/// the ETag-cache budget (350 MB of *body* blobs) — the SQLite file carries
/// page/free-space overhead, and debug runs leave JIT kernel snapshots in tmp.
/// The system URL cache used to keep its own copy of HTTP responses too, but
/// it is now disabled at startup ([StorageScanner.configure]) so every cached
/// byte lives in the app's own SQLite; the Debug page needs real numbers, so
/// this scans the platform's cache/support/document/tmp trees once and splits
/// the result into the app's own top-level directories plus the biggest
/// individual files.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// One scanned top-level directory (or large file).
class StorageEntry {
  const StorageEntry({required this.path, required this.bytes});

  final String path;
  final int bytes;

  /// File name (or last path component) — what the Debug page shows.
  String get name => path.split('/').last;

  /// The last two path components (`tmp/main.dart.dill`) — enough to tell
  /// which sandbox tree a file lives in when several share a name.
  String get shortPath {
    final parts = path.split('/');
    return parts.length >= 2
        ? '${parts[parts.length - 2]}/${parts.last}'
        : name;
  }
}

/// Result of a sandbox scan.
class StorageScan {
  const StorageScan({
    required this.totalBytes,
    required this.dirs,
    required this.files,
  });

  /// Everything under the sandbox's cache/support/document/tmp trees.
  final int totalBytes;

  /// Top-level directories, each with its total size.
  final List<StorageEntry> dirs;

  /// The largest individual files (above the platform's reporting floor),
  /// descending.
  final List<StorageEntry> files;
}

/// Formats a byte count as a compact human string (B / KB / MB / GB).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
}

/// One slice of the storage breakdown — a label plus its bytes.
class StorageSlice {
  const StorageSlice({required this.label, required this.bytes});

  final String label;
  final int bytes;
}

/// Splits a [StorageScan] into the app's own categories.
///
/// Known file names are matched first (SQLite DB + its `-wal`/`-shm`
/// companions, MapLibre's DB, the engine's caches, the system HTTP cache),
/// subtracted from the directory that contains them, and the remainder is
/// attributed to the directory itself. Files below the platform's reporting
/// floor stay inside their directory bucket, so slices may not sum exactly to
/// [StorageScan.totalBytes] — they are close enough for a pie chart.
List<StorageSlice> storageBreakdown(StorageScan scan) {
  final slices = <String, int>{};
  final dirBytes = {for (final d in scan.dirs) d.path: d.bytes};

  // /var is a symlink to /private/var on iOS; normalize either spelling so a
  // file always matches the directory that contains it.
  String varPath(String path) => path.replaceFirst('/private/var', '/var');

  String? dirOf(String path) {
    for (final dir in scan.dirs) {
      if (path.startsWith(dir.path)) return dir.path;
      // iOS can hand one side /private/var and the other /var — treat them
      // as the same tree so the subtraction still lands.
      if (varPath(path).startsWith(varPath(dir.path))) return dir.path;
    }
    return null;
  }

  void known(String label, bool Function(StorageEntry) match) {
    var sum = 0;
    for (final file in scan.files) {
      if (!match(file)) continue;
      sum += file.bytes;
      final dir = dirOf(file.path);
      if (dir != null) dirBytes[dir] = dirBytes[dir]! - file.bytes;
    }
    if (sum > 0) slices[label] = (slices[label] ?? 0) + sum;
  }

  known('ETag cache (SQLite)', (f) => f.name.startsWith('http_etag_cache.db'));
  // Native-written movement history, budgeted at 50 MB. It grows without
  // anybody opening anything, so it is the one slice a user could otherwise
  // find no explanation for. `startsWith` catches the -wal and -shm companions.
  known('Location track', (f) => f.name.startsWith('location_track.db'));
  known(
    'MapLibre',
    (f) => f.path.contains('MapLibre') || f.path.contains('mapbox'),
  );
  known(
    'Flutter engine',
    // `io.flutter` covers the engine's own caches; `*.dill` covers the
    // debug-mode kernel snapshots flutter run leaves in tmp on every launch
    // (tens of MB each, and they pile up — they are not app data).
    (f) => f.path.contains('io.flutter') || f.name.endsWith('.dill'),
  );
  known(
    'System HTTP cache',
    // Residue only: [configure] disables the disk cache at startup, so this
    // slice exists to explain bytes left by older builds until a clear.
    (f) => f.path.contains('HTTPCache') || f.path.contains('URLCache'),
  );

  for (final dir in scan.dirs) {
    final bytes = dirBytes[dir.path] ?? 0;
    if (bytes <= 0) {
      continue;
    }
    // A directory that gave up a known file keeps the rest; say so in the
    // label so the pie reads as ETag being *part of* Caches, not a sibling.
    final label = bytes < dir.bytes ? '${dir.name} (other)' : dir.name;
    slices[label] = (slices[label] ?? 0) + bytes;
  }

  final accounted = slices.values.fold(0, (a, b) => a + b);
  final out = [
    for (final entry in slices.entries)
      StorageSlice(label: entry.key, bytes: entry.value),
  ]..sort((a, b) => b.bytes.compareTo(a.bytes));
  // Files below the platform's reporting floor are invisible to the
  // per-file pass, so fold the difference into "Other" — the pie then sums
  // exactly to what Settings reports.
  if (accounted < scan.totalBytes) {
    out.add(StorageSlice(label: 'Other', bytes: scan.totalBytes - accounted));
  }
  return out;
}

/// App-owned native bridge (iOS `StorageScanPlugin`, Android
/// `StorageScanChannel`).
class StorageScanner {
  const StorageScanner();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/storage_scan',
  );

  /// Measures the sandbox. Best-effort — an error yields an empty scan rather
  /// than a broken Debug page.
  Future<StorageScan> scan() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('scan');
      if (raw == null) {
        return const StorageScan(totalBytes: 0, dirs: [], files: []);
      }
      List<StorageEntry> entries(String key) => [
        for (final row in (raw[key] as List? ?? const []))
          StorageEntry(
            path: (row as Map)['path'] as String,
            bytes: (row['bytes'] as num).toInt(),
          ),
      ];
      return StorageScan(
        totalBytes: (raw['totalBytes'] as num?)?.toInt() ?? 0,
        dirs: entries('dirs'),
        files: entries('files'),
      );
    } on MissingPluginException {
      return const StorageScan(totalBytes: 0, dirs: [], files: []);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'storage scan');
      return const StorageScan(totalBytes: 0, dirs: [], files: []);
    }
  }

  /// One-shot startup tuning: the system disk HTTP cache (iOS NSURLCache) is
  /// **disabled** — MapLibre's downloads are persisted in the app's own SQLite
  /// through the tile bridge, so a second disk copy is pure overhead — and any
  /// residue from before this ran is dropped. Android has no equivalent to
  /// configure.
  Future<void> configure() async {
    try {
      await _channel.invokeMethod<void>('configure');
    } on MissingPluginException {
      // Platform without the handler.
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'storage configure');
    }
  }

  /// Empties the OS-level HTTP cache (iOS NSURLCache). Android is a no-op —
  /// the plugins' caches live in the app's own SQLite, already covered by the
  /// ETag-cache clear.
  Future<void> clearSystemHttpCache() async {
    try {
      await _channel.invokeMethod<void>('clearSystemHttpCache');
    } on MissingPluginException {
      // Platform without the handler.
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'clear system HTTP cache');
    }
  }

  /// Empties the sandbox's temporary directory. iOS-only: Android has no
  /// separate tmp tree — `cacheDir` is the whole story and is covered by the
  /// cache clear already.
  ///
  /// Nothing the app owns lives in tmp permanently, so this is always safe;
  /// it exists because some native path (historically MapLibre's transient
  /// tile work, aborted snapshot writes) can pile up hundreds of MB there
  /// that no other clear reaches.
  Future<void> clearTmp() async {
    try {
      await _channel.invokeMethod<void>('clearTmp');
    } on MissingPluginException {
      // Platform without the handler (Android — no-op by design).
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'clear tmp');
    }
  }
}
