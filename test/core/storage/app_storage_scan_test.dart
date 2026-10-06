import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:flutter/services.dart';
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
        slices.firstWhere((s) => s.label == 'caches (other)').bytes,
        20 * 1024 * 1024,
      );
    });

    test('a dir that gave up a known file is labelled with (other)', () {
      final s = scan(
        totalBytes: 210 * 1024 * 1024,
        dirs: const [StorageEntry(path: '/caches', bytes: 210 * 1024 * 1024)],
        files: const [
          StorageEntry(
            path: '/caches/http_etag_cache.db',
            bytes: 150 * 1024 * 1024,
          ),
        ],
      );
      final slices = storageBreakdown(s);
      expect(slices.any((s) => s.label == 'caches (other)'), isTrue);
      // A directory that kept everything keeps its plain name.
      expect(slices.any((s) => s.label == 'caches'), isFalse);
    });

    test('/private/var and /var spellings match the same directory', () {
      final s = scan(
        totalBytes: 300 * 1024 * 1024,
        dirs: const [
          StorageEntry(path: '/var/.../Caches', bytes: 300 * 1024 * 1024),
        ],
        files: const [
          StorageEntry(
            path: '/private/var/.../Caches/http_etag_cache.db',
            bytes: 200 * 1024 * 1024,
          ),
        ],
      );
      final slices = storageBreakdown(s);
      expect(
        slices.firstWhere((s) => s.label == 'ETag cache (SQLite)').bytes,
        200 * 1024 * 1024,
      );
      expect(
        slices.firstWhere((s) => s.label == 'Caches (other)').bytes,
        100 * 1024 * 1024,
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
      // Nothing was subtracted, so the directory keeps its plain name.
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
        slices.firstWhere((s) => s.label == 'tmp (other)').bytes,
        10 * 1024 * 1024,
      );
    });
  });

  group('formatBytes', () {
    test('human-friendly units', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(12 * 1024), '12 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(700 * 1024 * 1024), '700 MB');
      expect(formatBytes(1024 * 1024 * 1024), '1.0 GB');
      expect(formatBytes(10 * 1024 * 1024 * 1024), '10 GB');
      expect(formatBytes(1024 * 1024 * 1024 * 1024), '1.0 TB');
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

    test('a single path component is its own name', () {
      const entry = StorageEntry(path: 'orphan.db', bytes: 1);
      expect(entry.shortPath, 'orphan.db');
      expect(entry.name, 'orphan.db');
    });
  });

  group('storageBreakdown extra buckets', () {
    StorageScan scan({
      required int totalBytes,
      List<StorageEntry> dirs = const [],
      List<StorageEntry> files = const [],
    }) => StorageScan(totalBytes: totalBytes, dirs: dirs, files: files);

    test('location track, mapbox and URLCache each get their own slice', () {
      final slices = storageBreakdown(
        scan(
          totalBytes: 90,
          dirs: const [StorageEntry(path: '/caches', bytes: 90)],
          files: const [
            StorageEntry(path: '/caches/location_track.db', bytes: 20),
            StorageEntry(path: '/caches/location_track.db-wal', bytes: 5),
            StorageEntry(path: '/caches/mapbox/cache.db', bytes: 30),
            StorageEntry(path: '/caches/URLCache/x', bytes: 15),
          ],
        ),
      );
      expect(slices.firstWhere((s) => s.label == 'Location track').bytes, 25);
      expect(slices.firstWhere((s) => s.label == 'MapLibre').bytes, 30);
      expect(
        slices.firstWhere((s) => s.label == 'System HTTP cache').bytes,
        15,
      );
      expect(slices.firstWhere((s) => s.label == 'caches (other)').bytes, 20);
    });

    test('a file outside every directory is still counted, and a '
        'fully consumed directory disappears', () {
      final slices = storageBreakdown(
        scan(
          totalBytes: 80,
          dirs: const [StorageEntry(path: '/caches', bytes: 10)],
          files: const [
            StorageEntry(path: '/elsewhere/location_track.db', bytes: 40),
            StorageEntry(path: '/caches/http_etag_cache.db', bytes: 10),
          ],
        ),
      );
      expect(slices.firstWhere((s) => s.label == 'Location track').bytes, 40);
      expect(
        slices.firstWhere((s) => s.label == 'ETag cache (SQLite)').bytes,
        10,
      );
      expect(slices.any((s) => s.label.startsWith('caches')), isFalse);
      expect(slices.firstWhere((s) => s.label == 'Other').bytes, 30);
    });

    test('directories that share a name merge into one slice', () {
      final slices = storageBreakdown(
        scan(
          totalBytes: 30,
          dirs: const [
            StorageEntry(path: '/a/tmp', bytes: 10),
            StorageEntry(path: '/b/tmp', bytes: 20),
          ],
        ),
      );
      expect(slices.single.label, 'tmp');
      expect(slices.single.bytes, 30);
    });
  });

  group('StorageScanner', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('com.exptech.dpip/storage_scan');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test(
      'parses directories and files, and treats a missing total as zero',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'scan');
          return <String, Object?>{
            'dirs': [
              {'path': '/caches', 'bytes': 12},
            ],
            'files': [
              {'path': '/caches/note.txt', 'bytes': 3.0},
            ],
          };
        });
        final scan = await const StorageScanner().scan();
        expect(scan.totalBytes, 0);
        expect(scan.dirs.single.path, '/caches');
        expect(scan.dirs.single.bytes, 12);
        expect(scan.files.single.bytes, 3);
      },
    );

    test('a null payload is an empty scan', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      final scan = await const StorageScanner().scan();
      expect(scan.totalBytes, 0);
      expect(scan.dirs, isEmpty);
      expect(scan.files, isEmpty);
    });

    test('a row that is not a map becomes an empty scan', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'totalBytes': 4,
          'dirs': [1],
        };
      });
      final scan = await const StorageScanner().scan();
      expect(scan.totalBytes, 0);
      expect(scan.dirs, isEmpty);
    });

    test(
      'a missing plugin and a thrown error both become an empty scan',
      () async {
        messenger.setMockMethodCallHandler(channel, null);
        final missing = await const StorageScanner().scan();
        expect(missing.dirs, isEmpty);

        messenger.setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'scan');
        });
        final failed = await const StorageScanner().scan();
        expect(failed.files, isEmpty);

        messenger.setMockMethodCallHandler(channel, (call) async {
          throw StateError('scan');
        });
        final other = await const StorageScanner().scan();
        expect(other.totalBytes, 0);
      },
    );

    test('configure and the clears succeed, ignore a missing plugin, and '
        'swallow a platform error', () async {
      const scanner = StorageScanner();
      for (final method in ['configure', 'clearSystemHttpCache', 'clearTmp']) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, method);
          return null;
        });
        await _invoke(scanner, method);

        messenger.setMockMethodCallHandler(channel, null);
        await _invoke(scanner, method);

        messenger.setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: method);
        });
        await _invoke(scanner, method);

        messenger.setMockMethodCallHandler(channel, (call) async {
          throw StateError(method);
        });
        await _invoke(scanner, method);
      }
    });
  });
}

Future<void> _invoke(StorageScanner scanner, String method) {
  return switch (method) {
    'configure' => scanner.configure(),
    'clearSystemHttpCache' => scanner.clearSystemHttpCache(),
    _ => scanner.clearTmp(),
  };
}
