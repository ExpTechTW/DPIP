import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('storageBreakdown', () {
    StorageScan scan({
      int totalBytes = 700 * 1024 * 1024,
      List<StorageEntry> dirs = const [],
      List<StorageEntry> files = const [],
    }) => StorageScan(totalBytes: totalBytes, dirs: dirs, files: files);

    test('known big files are pulled out of their directory', () {
      final s = scan(
        totalBytes: 300 * 1024 * 1024,
        dirs: const [
          StorageEntry(path: '/caches', bytes: 200 * 1024 * 1024),
          StorageEntry(path: '/support', bytes: 100 * 1024 * 1024),
        ],
        files: const [
          StorageEntry(
            path: '/caches/http_etag_cache.db',
            bytes: 180 * 1024 * 1024,
          ),
          StorageEntry(
            path: '/support/MapLibre/cache.db',
            bytes: 60 * 1024 * 1024,
          ),
        ],
      );
      final slices = storageBreakdown(s);
      expect(
        slices,
        contains(
          predicate<StorageSlice>((s) => s.label == 'ETag cache (SQLite)'),
        ),
      );
      expect(
        slices.firstWhere((s) => s.label == 'ETag cache (SQLite)').bytes,
        180 * 1024 * 1024,
      );
      expect(
        slices.firstWhere((s) => s.label == 'MapLibre').bytes,
        60 * 1024 * 1024,
      );
      // The cache directory keeps the leftover after the DB is subtracted.
      expect(
        slices.firstWhere((s) => s.label == 'caches').bytes,
        20 * 1024 * 1024,
      );
    });

    test('the -wal and -shm companions count with the SQLite db', () {
      final s = scan(
        totalBytes: 210 * 1024 * 1024,
        dirs: const [StorageEntry(path: '/caches', bytes: 210 * 1024 * 1024)],
        files: const [
          StorageEntry(
            path: '/caches/http_etag_cache.db',
            bytes: 150 * 1024 * 1024,
          ),
          StorageEntry(
            path: '/caches/http_etag_cache.db-wal',
            bytes: 40 * 1024 * 1024,
          ),
        ],
      );
      final slices = storageBreakdown(s);
      expect(
        slices.firstWhere((s) => s.label == 'ETag cache (SQLite)').bytes,
        190 * 1024 * 1024,
      );
    });

    test('the difference below the file-reporting floor becomes Other', () {
      final s = scan(
        totalBytes: 100 * 1024 * 1024,
        dirs: const [StorageEntry(path: '/caches', bytes: 80 * 1024 * 1024)],
        // No large files: everything stays inside the directory bucket…
        files: const [],
      );
      final slices = storageBreakdown(s);
      // …but totalBytes is the whole sandbox, so the unseen 20 MB is Other.
      expect(
        slices.firstWhere((s) => s.label == 'Other').bytes,
        20 * 1024 * 1024,
      );
      expect(
        slices.firstWhere((s) => s.label == 'caches').bytes,
        80 * 1024 * 1024,
      );
    });

    test('system HTTP cache and engine caches get their own labels', () {
      final s = scan(
        totalBytes: 90 * 1024 * 1024,
        dirs: const [StorageEntry(path: '/caches', bytes: 90 * 1024 * 1024)],
        files: const [
          StorageEntry(path: '/caches/HTTPCache/123', bytes: 50 * 1024 * 1024),
          StorageEntry(path: '/caches/io.flutter/x', bytes: 30 * 1024 * 1024),
        ],
      );
      final slices = storageBreakdown(s);
      expect(
        slices.firstWhere((s) => s.label == 'System HTTP cache').bytes,
        50 * 1024 * 1024,
      );
      expect(
        slices.firstWhere((s) => s.label == 'Flutter engine').bytes,
        30 * 1024 * 1024,
      );
    });

    test('debug kernel snapshots (*.dill) count as engine, not tmp', () {
      final s = scan(
        totalBytes: 190 * 1024 * 1024,
        dirs: const [StorageEntry(path: '/tmp', bytes: 190 * 1024 * 1024)],
        files: const [
          StorageEntry(path: '/tmp/main.dart.dill', bytes: 90 * 1024 * 1024),
          StorageEntry(
            path: '/tmp/main.dart.swap.dill',
            bytes: 90 * 1024 * 1024,
          ),
        ],
      );
      final slices = storageBreakdown(s);
      expect(
        slices.firstWhere((s) => s.label == 'Flutter engine').bytes,
        180 * 1024 * 1024,
      );
      expect(
        slices.firstWhere((s) => s.label == 'tmp').bytes,
        10 * 1024 * 1024,
      );
    });
  });

  group('formatBytes', () {
    test('human-friendly units', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(700 * 1024 * 1024), '700 MB');
    });
  });

  group('StorageEntry.shortPath', () {
    test('keeps the containing directory', () {
      const entry = StorageEntry(
        path: '/var/mobile/.../tmp/main.dart.dill',
        bytes: 1,
      );
      expect(entry.shortPath, 'tmp/main.dart.dill');
    });
  });
}
