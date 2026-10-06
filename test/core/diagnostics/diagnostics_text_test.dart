/// The pasted half of a dump. Precise location needs consent; support lookup
/// identifiers and push tokens remain useful and cannot be acted on by a user.
library;

import 'dart:io';

import 'package:dpip/core/diagnostics/diagnostics_report.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../storage/memory_db.dart';

void main() {
  test('only precise location is redacted', () {
    final text = diagnosticsText([
      (
        title: 'Device',
        fields: [
          (label: 'Model', value: 'iPhone17,1'),
          (label: 'Identifier', value: 'D4E7-PRIVATE'),
        ],
      ),
      (title: 'Push', fields: [(label: 'APNs token', value: 'SECRET-TOKEN')]),
      (
        title: 'Location',
        fields: [(label: 'Centred on', value: '25.0478, 121.5319')],
      ),
    ], redacted: diagnosticsSensitiveLabels);

    expect(text, contains('iPhone17,1'));
    expect(text, contains('D4E7-PRIVATE'));
    expect(text, contains('SECRET-TOKEN'));
    expect(text, isNot(contains('25.0478')));
    expect(text, isNot(contains('Centred on')));
  });

  test('a section left with nothing to say is dropped whole', () {
    final text = diagnosticsText([
      (
        title: 'Location',
        fields: [(label: 'Centred on', value: '25.0478, 121.5319')],
      ),
    ], redacted: diagnosticsSensitiveLabels);

    expect(text, isNot(contains('[Location]')));
  });

  test('a field the platform could not answer reads as a dash, not blank', () {
    final text = diagnosticsText([
      (title: 'Platform', fields: [(label: 'OS version', value: null)]),
    ]);

    // A blank after the colon looks like a formatting bug; the dash says the
    // field was asked for and came back empty.
    expect(text, contains('OS version: —'));
  });

  test('nothing redacted by default', () {
    final text = diagnosticsText([
      (title: 'Device', fields: [(label: 'Identifier', value: 'VISIBLE')]),
    ]);

    // The redaction is the caller's decision: the Developer page shows these
    // rows on screen and only strips them on the way out.
    expect(text, contains('VISIBLE'));
  });

  test('sensitive fields can remain visible with null values', () {
    final text = diagnosticsText([
      (
        title: 'Private',
        fields: [
          (label: 'Identifier', value: 'PRIVATE-ID'),
          (label: 'Centred on', value: '25.0478, 121.5319'),
        ],
      ),
    ], nulled: diagnosticsSensitiveLabels);

    expect(text, contains('Identifier: PRIVATE-ID'));
    expect(text, contains('Centred on: null'));
    expect(text, isNot(contains('25.0478')));
  });

  // The private formatters only run inside DiagnosticsCollector.collect.
  // Android/iOS-only rows (push token, restricted execution, standby bucket,
  // vendor manager, unused-app exempt/restricted) stay dark: dart:io Platform
  // cannot be overridden, and that gap is intentional.
  group('DiagnosticsCollector.collect', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const bgChannel = MethodChannel('test/background_location');
    const deviceChannel = MethodChannel('com.exptech.dpip/device_info');
    const packageChannel = MethodChannel(
      'dev.fluttercommunity.plus/package_info',
    );
    const storageChannel = MethodChannel('com.exptech.dpip/storage_scan');

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    late Directory support;
    late Map<String, Object?> bgPayload;
    late Object? storagePayload;
    late _SupportPaths paths;

    setUp(() {
      support = Directory.systemTemp.createTempSync('dpip-diag');
      paths = _SupportPaths(support.path);
      PathProviderPlatform.instance = paths;
      bgPayload = const {};
      storagePayload = _storagePayload;
      PackageInfo.setMockInitialValues(
        appName: 'DPIP',
        packageName: 'com.exptech.dpip',
        version: '26.1.0',
        buildNumber: '9',
        buildSignature: '',
      );
      messenger.setMockMethodCallHandler(bgChannel, (call) async {
        if (call.method == 'diagnostics') return bgPayload;
        return null;
      });
      messenger.setMockMethodCallHandler(deviceChannel, (call) async {
        return <String, Object?>{
          'manufacturer': 'TestCo',
          'model': 'TestPhone',
          'osVersion': '26',
          'sdkInt': 34,
          'identifier': 'device-1',
        };
      });
      messenger.setMockMethodCallHandler(packageChannel, (call) async {
        return <String, Object?>{
          'appName': 'DPIP',
          'packageName': 'com.exptech.dpip',
          'version': '26.1.0',
          'buildNumber': '9',
        };
      });
      messenger.setMockMethodCallHandler(
        storageChannel,
        (call) async => storagePayload,
      );
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(bgChannel, null);
      messenger.setMockMethodCallHandler(deviceChannel, null);
      messenger.setMockMethodCallHandler(packageChannel, null);
      messenger.setMockMethodCallHandler(storageChannel, null);
      if (support.existsSync()) support.deleteSync(recursive: true);
    });

    int ago(Duration age) =>
        DateTime.now().subtract(age).millisecondsSinceEpoch;
    int ahead(Duration age) => DateTime.now().add(age).millisecondsSinceEpoch;

    Future<DiagnosticsReport> collect({
      EtagCacheStore? etag,
      NetworkUsageStore? usage,
      AppDatabase? database,
    }) {
      return DiagnosticsCollector(
        notifications: NotificationService(SettingsStore.inMemory()),
        database: database ?? const AppDatabase(durable: null, cache: null),
        backgroundLocation: BackgroundLocationService(
          platform: 0,
          version: '1',
          channel: bgChannel,
        ),
        etagCache: etag,
        networkUsage: usage,
      ).collect();
    }

    test(
      'formats every reachable background, storage and cache branch',
      () async {
        final cacheDb = openMemoryDb();
        addTearDown(cacheDb.close);
        await EtagCacheStore.createSchema(cacheDb);
        await NetworkUsageStore.createSchema(cacheDb);
        await cacheDb.execute(
          'INSERT INTO http_cache '
          '(key, etag, content_type, kind, body, size, time) '
          'VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            'https://example.test',
            'e',
            'text/plain',
            0,
            Uint8List(2048),
            2048,
            5,
          ],
        );
        final etag = EtagCacheStore(cacheDb);
        final usage = NetworkUsageStore(cacheDb, flushEvery: 64);
        addTearDown(usage.flush);
        await usage.record(down: 2048, hit: true, saved: 1024);

        final tables = openMemoryDb();
        addTearDown(tables.close);
        await tables.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)',
        );
        await tables.execute("INSERT INTO notes (body) VALUES ('hello')");

        final trackPath = '${support.path}/location_track.db';
        final track = sqlite3.sqlite3.open(trackPath);
        track.execute(
          'CREATE TABLE fix (id INTEGER PRIMARY KEY, t INTEGER NOT NULL, '
          'lat INTEGER NOT NULL, lng INTEGER NOT NULL)',
        );
        track.execute('INSERT INTO fix (id, t, lat, lng) VALUES (0, 1, 2, 3)');
        track.close();

        bgPayload = {
          'enabled': true,
          'authorization': 'always',
          'armed': false,
          'blocked': 'permission',
          'spine': 'geofence',
          'hasToken': true,
          'wakeGeofence': 2,
          'wakeAlarm': 1,
          'wakeBoot': 3,
          'lastGeofenceError': 'region rejected',
          'lastGeofenceTransitionAt': ago(const Duration(seconds: 20)),
          'lastAttemptAt': ago(const Duration(minutes: 5, seconds: 20)),
          'lastAttemptOk': true,
          'lastAttemptCode': 200,
          'lastSuccessAt': ago(const Duration(hours: 3, minutes: 5)),
          'lastSuccessCode': 204,
          'throttledCount': 2,
          'lastThrottledAt': ago(const Duration(days: 2, hours: 1)),
          'nextAlarmAt': ahead(const Duration(minutes: 10, seconds: 30)),
          'watchdogState': 'scheduled',
          'watchdogScheduled': true,
          'watchdogOverdue': false,
          'watchdogNextAt': ahead(const Duration(hours: 1, minutes: 5)),
          'watchdogRunCount': 4,
          'watchdogLastRunAt': ago(const Duration(hours: 3, minutes: 5)),
          'watchdogRepairCount': 1,
          'watchdogLastRepairAt': ago(const Duration(days: 2, hours: 1)),
          'centreLat': 25.0333,
          'centreLng': 121.5654,
          'detail': 'armed on the geofence',
        };

        final rich = await collect(
          etag: etag,
          usage: usage,
          database: AppDatabase(durable: tables, cache: tables),
        );
        final text = diagnosticsText(rich.sections);

        expect(text, contains('OS: ${Platform.operatingSystem}'));
        expect(text, contains('Build mode: debug'));
        expect(text, contains('Android API level: 34'));
        expect(text, contains('Manufacturer: TestCo'));
        expect(text, contains('Identifier: device-1'));
        expect(text, contains('Store version: 26.1.0 (9)'));
        expect(text, isNot(contains('[Push]')));
        expect(text, contains('Requested: yes'));
        expect(text, contains('Armed: no'));
        expect(text, contains('Blocked by: permission'));
        expect(text, contains('Wakes: geofence 2 · alarm 1 · boot 3'));
        expect(text, contains('Track fixes: 1 ·'));
        expect(text, contains('Geofence error: region rejected'));
        expect(text, contains('Last geofence exit: moments ago'));
        expect(text, contains('Last attempt: 5 min ago · ok (200)'));
        expect(text, contains('Last success: 3 h ago · 204'));
        expect(text, contains('Throttle skips: 2 · last 2 d ago'));
        expect(text, contains('Next alarm: in 10 min'));
        expect(text, contains('Watchdog: scheduled · healthy · in 1 h'));
        expect(text, contains('Watchdog runs: 4 · last 3 h ago'));
        expect(text, contains('Watchdog repair attempts: 1 · last 2 d ago'));
        expect(text, contains('Centred on: 25.0333, 121.5654'));
        expect(text, contains('Background execution: unknown'));
        expect(text, contains('Kept active: n/a'));
        expect(text, isNot(contains('Vendor power manager')));
        expect(text, isNot(contains('Standby bucket')));
        expect(text, contains('Entries: 1'));
        expect(text, contains('Size on disk: 2.0 KB'));
        expect(text, contains('Downloaded · last 24h: 2.0 KB'));
        expect(text, contains('Hit rate · last 24h: 100% (1/1)'));
        expect(text, contains('Hit rate · last 7d: 100% (1/1)'));
        expect(text, contains('Total on disk: 2.0 GB'));
        expect(text, contains('Largest files: —'));
        expect(text, contains('caches/http_etag_cache.db:'));
        expect(text, contains('orphan.db: 1.5 KB'));
        expect(
          text,
          anyOf(
            contains('Measured: on-disk pages (dbstat)'),
            contains('Measured: payload only (no dbstat)'),
          ),
        );
        expect(rich.usageHistory, isNotNull);
        expect(rich.usageWeek, isNotNull);
        expect(rich.tables, isNotEmpty);

        // Ages, outcome codes, watchdog health and the empty readings.
        final cases = <(Map<String, Object?>, String)>[
          (
            {
              'lastReportAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastReportOk': false,
              'lastReportCode': -2,
            },
            'no push token',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': false,
              'lastAttemptCode': -3,
            },
            'no app version',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': false,
              'lastAttemptCode': -4,
            },
            'throttled (a report went out under a minute ago)',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': false,
              'lastAttemptCode': -1,
            },
            'could not reach the server',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': false,
              'lastAttemptCode': 500,
            },
            'failed (500)',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': true,
              'lastAttemptCode': 'n/a',
            },
            'Last attempt: 4 min ago · ok',
          ),
          (
            {
              'lastAttemptAt': ago(const Duration(minutes: 4, seconds: 20)),
              'lastAttemptOk': false,
              'lastAttemptCode': 'n/a',
            },
            'Last attempt: 4 min ago · failed',
          ),
          ({}, 'Last attempt: never'),
          (
            {
              'lastReportAt': ago(const Duration(hours: 6, minutes: 5)),
              'lastReportOk': true,
              'lastReportCode': 201,
            },
            'Last success: 6 h ago · 201',
          ),
          (
            {
              'lastSuccessAt': ago(const Duration(days: 2, hours: 1)),
              'lastSuccessCode': 'n/a',
            },
            'Last success: 2 d ago',
          ),
          (const {}, 'Last success: never'),
          ({'throttledCount': 0}, 'Throttle skips: none'),
          ({'throttledCount': 4}, 'Throttle skips: 4'),
          (
            {'nextAlarmAt': ago(const Duration(minutes: 1))},
            'Next alarm: due (OS may deliver it late)',
          ),
          (const {'nextAlarmAt': 'soon'}, 'Next alarm: —'),
          (
            {
              'watchdogState': 'query unavailable',
              'watchdogNextAt': ahead(const Duration(minutes: 30, seconds: 30)),
            },
            'query unavailable · health unknown · in 30 min',
          ),
          (
            {'watchdogState': 'idle', 'watchdogScheduled': false},
            'idle · NOT SCHEDULED · next unknown',
          ),
          (
            {
              'watchdogState': 'scheduled',
              'watchdogScheduled': true,
              'watchdogOverdue': true,
              'watchdogNextAt': ago(const Duration(minutes: 8, seconds: 20)),
            },
            'scheduled · OVERDUE · 8 min ago',
          ),
          (
            {
              'watchdogState': 'scheduled',
              'watchdogRunCount': 'nope',
              'watchdogLastRunAt': ahead(
                const Duration(minutes: 2, seconds: 30),
              ),
            },
            'Watchdog runs: 0 · last in 2 min',
          ),
          (
            {'watchdogState': 'scheduled', 'watchdogRepairCount': 0},
            'Watchdog repair attempts: 0 · last never',
          ),
          ({'lastGeofenceTransitionAt': 'nope'}, 'Last geofence exit: never'),
          ({'wakeAlarm': 1}, 'Wakes: alarm 1'),
          (const {}, 'Wakes: never woken'),
          ({'centreLat': 1, 'centreLng': 2}, 'Centred on: —'),
          ({'enabled': null, 'armed': null, 'hasToken': null}, 'Requested: —'),
        ];

        File(trackPath).deleteSync();
        storagePayload = null;
        for (final (payload, phrase) in cases) {
          bgPayload = {'enabled': false, 'hasToken': false, ...payload};
          final report = await collect();
          final body = diagnosticsText(report.sections);
          expect(body, contains(phrase), reason: phrase);
          expect(body, contains('Entries: —'));
          expect(body, contains('Downloaded · last 24h: —'));
          expect(body, contains('Hit rate · last 24h: —'));
          expect(body, contains('Measured: —'));
          expect(body, contains('Total on disk: 0 B'));
          expect(body, isNot(contains('Track fixes')));
          expect(report.usageHistory, isNull);
          expect(report.tables, isEmpty);
        }

        // An open store with no requests is a real zero, not "unknown".
        final emptyDb = openMemoryDb();
        addTearDown(emptyDb.close);
        await EtagCacheStore.createSchema(emptyDb);
        await NetworkUsageStore.createSchema(emptyDb);
        final emptyUsage = NetworkUsageStore(emptyDb, flushEvery: 64);
        addTearDown(emptyUsage.flush);
        bgPayload = const {'enabled': true};
        final empty = diagnosticsText(
          (await collect(
            usage: emptyUsage,
            etag: EtagCacheStore(emptyDb),
          )).sections,
        );
        expect(empty, contains('Downloaded · last 24h: 0 B'));
        expect(empty, contains('Hit rate · last 24h: —'));
        expect(empty, contains('Entries: 0'));
        expect(empty, contains('Size on disk: 0 B'));

        final missDb = openMemoryDb();
        addTearDown(missDb.close);
        await NetworkUsageStore.createSchema(missDb);
        final misses = NetworkUsageStore(missDb, flushEvery: 64);
        addTearDown(misses.flush);
        await misses.record(down: 512, hit: false, saved: 0);
        final missText = diagnosticsText(
          (await collect(usage: misses)).sections,
        );
        expect(missText, contains('Hit rate · last 24h: 0% (0/1)'));
        expect(missText, contains('Downloaded · last 24h: 512 B'));
      },
    );
  });
}

class _SupportPaths extends PathProviderPlatform {
  _SupportPaths(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

const _storagePayload = <String, Object?>{
  'totalBytes': 2 * 1024 * 1024 * 1024,
  'dirs': [
    {'path': '/caches', 'bytes': 1024 * 1024 * 1024},
  ],
  'files': [
    {'path': '/caches/http_etag_cache.db', 'bytes': 512 * 1024 * 1024},
    {'path': 'orphan.db', 'bytes': 1536},
  ],
};
