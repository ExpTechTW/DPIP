/// The developer page is what gets pasted into a bug report. A version row
/// that never unlocks, or a clear that runs without a confirm, would either
/// hide the experimental menu or wipe the cache by accident.
library;

import 'dart:async';
import 'dart:io';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/features/settings/presentation/pages/developer_page.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';

import '../../../../core/storage/memory_db.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(500, 5000);

const _bg = MethodChannel('test/background_location');
const _device = MethodChannel('com.exptech.dpip/device_info');
const _package = MethodChannel('dev.fluttercommunity.plus/package_info');
const _storage = MethodChannel('com.exptech.dpip/storage_scan');
const _maplibre = MethodChannel('plugins.flutter.io/maplibre_gl');
const _eew = MethodChannel('com.exptech.dpip/eew_live_activity');

const _start = 'Start Mock EEW';
const _generic = 'Start Generic Mock EEW';
const _update2 = 'Update → Report 2';
const _update4 = 'Update → Report 4';
const _arrived = 'Mark Wave Arrived';
const _alert = 'Mark Wave Arrived + Alert';
const _delayed = 'Test Delayed Arrival Alert (8s)';
const _end = 'End Activity';
const _refresh = 'Refresh status';
const _eewButtons = [
  _start,
  _generic,
  _update2,
  _update4,
  _arrived,
  _alert,
  _delayed,
  _end,
  _refresh,
];

Map<String, Object?> _eewStatus({
  bool supported = true,
  bool enabled = true,
  bool active = false,
  int? reportNo,
  bool waveArrived = false,
  bool generic = false,
  String? delayedAlertStatus,
}) => {
  'supported': supported,
  'enabled': enabled,
  'active': active,
  'reportNo': reportNo,
  'waveArrived': waveArrived,
  'generic': generic,
  'delayedAlertStatus': delayedAlertStatus,
};

Finder _eewButton(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
);

void _expectEewButtons(WidgetTester tester, Set<String> enabled) {
  for (final label in _eewButtons) {
    expect(
      tester.widget<ButtonStyleButton>(_eewButton(label)).onPressed != null,
      enabled.contains(label),
      reason: label,
    );
  }
}

Future<void> _pumpEewPage(WidgetTester tester) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = SettingsStore.inMemory();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider(create: (_) => NotificationService(store)),
        Provider.value(value: const AppDatabase(durable: null, cache: null)),
        Provider(
          create: (_) => BackgroundLocationService(
            platform: 0,
            version: '1',
            channel: _bg,
          ),
        ),
        Provider<EtagCacheStore?>.value(value: null),
        Provider<NetworkUsageStore?>.value(value: null),
        Provider<MapTileCache?>.value(value: null),
        ChangeNotifierProvider.value(value: ExperimentalSettings(store)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeveloperPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Developer'), findsOneWidget);
  expect(find.text('Maintenance'), findsOneWidget);
}

class _FakePaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(() {
    calls.clear();
    PathProviderPlatform.instance = _FakePaths();
    PackageInfo.setMockInitialValues(
      appName: 'DPIP',
      packageName: 'com.exptech.dpip',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    messenger.setMockMethodCallHandler(_bg, (call) async {
      calls.add('bg:${call.method}');
      if (call.method == 'diagnostics') {
        return <String, Object?>{
          'enabled': true,
          'authorization': 'always',
          'armed': false,
          'blocked': 'permission',
          'spine': 'geofence',
          'hasToken': true,
          'wakeGeofence': 2,
        };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(_device, (call) async {
      calls.add('device:${call.method}');
      return <String, Object?>{
        'manufacturer': 'Apple',
        'model': 'TestPhone',
        'osVersion': '26',
      };
    });
    messenger.setMockMethodCallHandler(_storage, (call) async {
      calls.add('storage:${call.method}');
      return null;
    });
    messenger.setMockMethodCallHandler(_maplibre, (call) async {
      calls.add('map:${call.method}');
      return null;
    });
    messenger.setMockMethodCallHandler(_package, (call) async {
      calls.add('pkg:${call.method}');
      return <String, Object?>{
        'appName': 'DPIP',
        'packageName': 'com.exptech.dpip',
        'version': '1.0.0',
        'buildNumber': '1',
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_bg, null);
    messenger.setMockMethodCallHandler(_device, null);
    messenger.setMockMethodCallHandler(_package, null);
    messenger.setMockMethodCallHandler(_storage, null);
    messenger.setMockMethodCallHandler(_maplibre, null);
    messenger.setMockMethodCallHandler(_eew, null);
  });

  group('debug EEW controls', () {
    testWidgets('shows loading until initial status completes', (tester) async {
      final pending = Completer<Map<String, Object?>>();
      final methods = <String>[];
      messenger.setMockMethodCallHandler(_eew, (call) {
        methods.add(call.method);
        return pending.future;
      });
      await _pumpEewPage(tester);
      expect(find.text('Checking Live Activity support…'), findsOneWidget);
      expect(methods, ['getStatus']);
      _expectEewButtons(tester, {_refresh});
      pending.complete(_eewStatus());
      await tester.pumpAndSettle();
      expect(find.text('Ready for a local mock'), findsOneWidget);
      _expectEewButtons(tester, {_start, _generic, _refresh});
    });

    final states = [
      (
        name: 'unsupported',
        status: _eewStatus(supported: false, enabled: false),
        text: 'Unavailable (requires iOS 16.1+)',
        enabled: {_refresh},
      ),
      (
        name: 'disabled',
        status: _eewStatus(enabled: false),
        text: 'Disabled in iOS settings',
        enabled: {_refresh},
      ),
      (
        name: 'ready',
        status: _eewStatus(),
        text: 'Ready for a local mock',
        enabled: {_start, _generic, _refresh},
      ),
      (
        name: 'active',
        status: _eewStatus(active: true, reportNo: 1),
        text: 'Mock active · report 1',
        enabled: {
          _update2,
          _update4,
          _arrived,
          _alert,
          _delayed,
          _end,
          _refresh,
        },
      ),
      (
        name: 'generic',
        status: _eewStatus(active: true, reportNo: 1, generic: true),
        text: 'Mock active · report 1',
        enabled: {_end, _refresh},
      ),
      (
        name: 'wave arrived',
        status: _eewStatus(active: true, reportNo: 4, waveArrived: true),
        text: 'Mock active · report 4 · wave arrived',
        enabled: {_end, _refresh},
      ),
      (
        name: 'delayed alert scheduled',
        status: _eewStatus(
          active: true,
          reportNo: 1,
          delayedAlertStatus: 'Scheduled',
        ),
        text: 'Mock active · report 1',
        enabled: {_update2, _update4, _arrived, _alert, _end, _refresh},
      ),
      (
        name: 'active but disabled in settings',
        status: _eewStatus(enabled: false, active: true, reportNo: 1),
        text: 'Disabled in iOS settings',
        enabled: {_update2, _update4, _arrived, _end, _refresh},
      ),
    ];
    for (final state in states) {
      testWidgets('${state.name} enables only eligible controls', (
        tester,
      ) async {
        final methods = <String>[];
        messenger.setMockMethodCallHandler(_eew, (call) async {
          methods.add(call.method);
          return state.status;
        });
        await _pumpEewPage(tester);
        expect(find.text(state.text), findsOneWidget);
        _expectEewButtons(tester, state.enabled);
        for (final label in _eewButtons.where(
          (b) => !state.enabled.contains(b),
        )) {
          await tester.tap(_eewButton(label));
        }
        await tester.pump();
        expect(methods, ['getStatus']);
      });
    }

    testWidgets('missing plugin keeps the diagnostic page usable', (
      tester,
    ) async {
      messenger.setMockMethodCallHandler(_eew, (_) async {
        throw MissingPluginException();
      });
      await _pumpEewPage(tester);
      expect(find.text('Unavailable (requires iOS 16.1+)'), findsOneWidget);
      _expectEewButtons(tester, {_refresh});
      expect(find.byTooltip('Copy all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starts, updates both reports, marks arrival, and ends', (
      tester,
    ) async {
      final methods = <MethodCall>[];
      var status = _eewStatus();
      messenger.setMockMethodCallHandler(_eew, (call) async {
        methods.add(call);
        status = switch (call.method) {
          'mockStart' => _eewStatus(active: true, reportNo: 1),
          'mockUpdate' => _eewStatus(
            active: true,
            reportNo: (call.arguments as Map)['reportNo'] as int,
          ),
          'mockWaveArrived' => _eewStatus(
            active: true,
            reportNo: 4,
            waveArrived: true,
          ),
          'mockEnd' => _eewStatus(),
          _ => status,
        };
        return status;
      });
      await _pumpEewPage(tester);
      for (final (label, text) in [
        (_start, 'Mock active · report 1'),
        (_update2, 'Mock active · report 2'),
        (_update4, 'Mock active · report 4'),
        (_arrived, 'Mock active · report 4 · wave arrived'),
        (_end, 'Ready for a local mock'),
      ]) {
        await tester.tap(_eewButton(label));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
      }
      expect(methods.map((c) => c.method), [
        'getStatus',
        'mockStart',
        'mockUpdate',
        'mockUpdate',
        'mockWaveArrived',
        'mockEnd',
      ]);
      expect(methods[2].arguments, {'reportNo': 2});
      expect(methods[3].arguments, {'reportNo': 4});
      _expectEewButtons(tester, {_start, _generic, _refresh});
    });

    testWidgets('generic start disables report and arrival controls', (
      tester,
    ) async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(_eew, (call) async {
        methods.add(call.method);
        return call.method == 'mockStartGeneric'
            ? _eewStatus(active: true, reportNo: 1, generic: true)
            : _eewStatus();
      });
      await _pumpEewPage(tester);
      await tester.tap(_eewButton(_generic));
      await tester.pumpAndSettle();
      expect(find.text('Mock active · report 1'), findsOneWidget);
      _expectEewButtons(tester, {_end, _refresh});
      await tester.tap(_eewButton(_end));
      await tester.pumpAndSettle();
      expect(methods, ['getStatus', 'mockStartGeneric', 'mockEnd']);
      expect(find.text('Ready for a local mock'), findsOneWidget);
    });

    testWidgets('arrival with alert displays explicit arrival', (tester) async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(_eew, (call) async {
        methods.add(call.method);
        return _eewStatus(
          active: true,
          reportNo: 2,
          waveArrived: call.method == 'mockWaveArrivedWithAlert',
        );
      });
      await _pumpEewPage(tester);
      await tester.tap(_eewButton(_alert));
      await tester.pumpAndSettle();
      expect(methods, ['getStatus', 'mockWaveArrivedWithAlert']);
      expect(
        find.text('Mock active · report 2 · wave arrived'),
        findsOneWidget,
      );
      _expectEewButtons(tester, {_end, _refresh});
    });

    testWidgets('delayed alert remains pending until refreshed native result', (
      tester,
    ) async {
      final methods = <String>[];
      var phase = 'Idle';
      messenger.setMockMethodCallHandler(_eew, (call) async {
        methods.add(call.method);
        if (call.method == 'mockScheduleDelayedArrivalAlert') {
          phase = 'Scheduled';
        }
        return _eewStatus(
          active: true,
          reportNo: 1,
          waveArrived: phase == 'Triggered',
          delayedAlertStatus: phase,
        );
      });
      await _pumpEewPage(tester);
      await tester.tap(_eewButton(_delayed));
      await tester.pumpAndSettle();
      expect(find.text('Delayed alert QA: Scheduled'), findsOneWidget);
      expect(find.text('Mock active · report 1'), findsOneWidget);
      _expectEewButtons(tester, {
        _update2,
        _update4,
        _arrived,
        _alert,
        _end,
        _refresh,
      });
      phase = 'Triggered';
      await tester.tap(_eewButton(_refresh));
      await tester.pumpAndSettle();
      expect(find.text('Delayed alert QA: Triggered'), findsOneWidget);
      expect(
        find.text('Mock active · report 1 · wave arrived'),
        findsOneWidget,
      );
      _expectEewButtons(tester, {_end, _refresh});
      expect(methods, [
        'getStatus',
        'mockScheduleDelayedArrivalAlert',
        'getStatus',
      ]);
    });

    for (final message in <String?>['Unable to read status', null]) {
      testWidgets(
        'status error ${message ?? 'code'} is displayed and refresh recovers',
        (tester) async {
          var fail = true;
          messenger.setMockMethodCallHandler(_eew, (_) async {
            if (fail) {
              throw PlatformException(code: 'status_error', message: message);
            }
            return _eewStatus();
          });
          await _pumpEewPage(tester);
          expect(find.text(message ?? 'status_error'), findsOneWidget);
          _expectEewButtons(tester, {_refresh});
          fail = false;
          await tester.tap(_eewButton(_refresh));
          await tester.pumpAndSettle();
          expect(find.text('Ready for a local mock'), findsOneWidget);
          expect(find.text(message ?? 'status_error'), findsNothing);
          _expectEewButtons(tester, {_start, _generic, _refresh});
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('failed refresh retains the active state and recovers', (
      tester,
    ) async {
      var fail = false;
      var status = _eewStatus(active: true, reportNo: 2);
      messenger.setMockMethodCallHandler(_eew, (_) async {
        if (fail) throw PlatformException(code: 'refresh_failed');
        return status;
      });
      await _pumpEewPage(tester);
      fail = true;
      await tester.tap(_eewButton(_refresh));
      await tester.pumpAndSettle();
      expect(find.text('refresh_failed'), findsOneWidget);
      _expectEewButtons(tester, {
        _update2,
        _update4,
        _arrived,
        _alert,
        _delayed,
        _end,
        _refresh,
      });
      fail = false;
      status = _eewStatus();
      await tester.tap(_eewButton(_refresh));
      await tester.pumpAndSettle();
      expect(find.text('refresh_failed'), findsNothing);
      expect(find.text('Ready for a local mock'), findsOneWidget);
      _expectEewButtons(tester, {_start, _generic, _refresh});
      expect(tester.takeException(), isNull);
    });

    final actions = {
      _start: 'mockStart',
      _generic: 'mockStartGeneric',
      _update2: 'mockUpdate',
      _update4: 'mockUpdate',
      _arrived: 'mockWaveArrived',
      _alert: 'mockWaveArrivedWithAlert',
      _delayed: 'mockScheduleDelayedArrivalAlert',
      _end: 'mockEnd',
    };
    for (final action in actions.entries) {
      testWidgets('${action.key} error preserves status and permits retry', (
        tester,
      ) async {
        final methods = <String>[];
        var fail = true;
        final isStart = action.key == _start || action.key == _generic;
        final status = isStart
            ? _eewStatus()
            : _eewStatus(active: true, reportNo: 1);
        messenger.setMockMethodCallHandler(_eew, (call) async {
          methods.add(call.method);
          if (call.method != 'getStatus' && fail) {
            throw PlatformException(
              code: 'activity_error',
              message: isStart ? null : 'Native action failed',
            );
          }
          return status;
        });
        await _pumpEewPage(tester);
        await tester.tap(_eewButton(action.key));
        await tester.pumpAndSettle();
        expect(
          find.text(isStart ? 'activity_error' : 'Native action failed'),
          findsOneWidget,
        );
        expect(find.text('Maintenance'), findsOneWidget);
        _expectEewButtons(
          tester,
          isStart
              ? {_start, _generic, _refresh}
              : {
                  _update2,
                  _update4,
                  _arrived,
                  _alert,
                  _delayed,
                  _end,
                  _refresh,
                },
        );
        fail = false;
        await tester.tap(_eewButton(action.key));
        await tester.pumpAndSettle();
        expect(methods, ['getStatus', action.value, action.value]);
        expect(
          find.text(
            isStart ? 'Ready for a local mock' : 'Mock active · report 1',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('busy operation rejects repeat taps before and after rebuild', (
      tester,
    ) async {
      final pending = Completer<Map<String, Object?>>();
      final methods = <String>[];
      messenger.setMockMethodCallHandler(_eew, (call) {
        methods.add(call.method);
        return call.method == 'getStatus'
            ? Future.value(_eewStatus())
            : pending.future;
      });
      await _pumpEewPage(tester);
      await tester.tap(_eewButton(_start));
      // No frame between taps: the old enabled button must still be guarded.
      await tester.tap(_eewButton(_start));
      await tester.tap(_eewButton(_generic));
      await tester.pump();
      expect(methods, ['getStatus', 'mockStart']);
      _expectEewButtons(tester, {});
      for (final label in _eewButtons) {
        await tester.tap(_eewButton(label));
      }
      await tester.pump();
      expect(methods, ['getStatus', 'mockStart']);
      pending.complete(_eewStatus(active: true, reportNo: 1));
      await tester.pumpAndSettle();
      expect(find.text('Mock active · report 1'), findsOneWidget);
      _expectEewButtons(tester, {
        _update2,
        _update4,
        _arrived,
        _alert,
        _delayed,
        _end,
        _refresh,
      });
    });

    for (final operation in ['getStatus', 'mockStart']) {
      for (final fail in [false, true]) {
        testWidgets(
          '$operation ${fail ? 'failure' : 'success'} after disposal is safe',
          (tester) async {
            final pending = Completer<Map<String, Object?>>();
            final methods = <String>[];
            messenger.setMockMethodCallHandler(_eew, (call) {
              methods.add(call.method);
              return call.method == operation
                  ? pending.future
                  : Future.value(_eewStatus());
            });
            await _pumpEewPage(tester);
            if (operation == 'mockStart') {
              await tester.tap(_eewButton(_start));
              await tester.pump();
            }
            expect(
              methods,
              operation == 'getStatus'
                  ? ['getStatus']
                  : ['getStatus', 'mockStart'],
            );
            await tester.pumpWidget(const SizedBox());
            if (fail) {
              pending.completeError(PlatformException(code: 'disposed'));
            } else {
              pending.complete(_eewStatus(active: true, reportNo: 1));
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  testWidgets('loads rows, unlocks on the tenth version tap, and confirms', (
    tester,
  ) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    PathProviderPlatform.instance = _FakePaths();
    final store = SettingsStore.inMemory();
    final experimental = ExperimentalSettings(store);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => NotificationService(store)),
          Provider.value(value: const AppDatabase(durable: null, cache: null)),
          Provider(
            create: (_) => BackgroundLocationService(
              platform: 0,
              version: '1',
              channel: _bg,
            ),
          ),
          Provider<EtagCacheStore?>.value(value: null),
          Provider<NetworkUsageStore?>.value(value: null),
          Provider<MapTileCache?>.value(value: null),
          ChangeNotifierProvider.value(value: experimental),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeveloperPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('TestPhone'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.byTooltip('Copy all'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pump();

    final version = find.text('Version');
    for (var i = 0; i < 9; i++) {
      await tester.tap(version);
      await tester.pump();
    }
    expect(experimental.unlocked, isFalse);
    expect(find.textContaining('more tap'), findsOneWidget);

    await tester.tap(version);
    await tester.pump();
    expect(experimental.unlocked, isTrue);
    expect(find.text('Experimental features unlocked'), findsOneWidget);

    await tester.tap(version);
    await tester.pump();
    expect(
      find.text('Experimental features are already unlocked'),
      findsOneWidget,
    );

    await tester.tap(find.text('Report location now'));
    await tester.pump();

    await tester.ensureVisible(find.text('Clear location track'));
    await tester.tap(find.text('Clear location track'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancel').last);
    await tester.pump();
    expect(experimental.unlocked, isTrue);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cancel'), findsWidgets);
    await tester.tap(find.text('Cancel').last);
    await tester.pump();
    expect(find.text('Maintenance'), findsOneWidget);
  });

  testWidgets('confirming clears the cache and the location track', (
    tester,
  ) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = SettingsStore.inMemory();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => NotificationService(store)),
          Provider.value(value: const AppDatabase(durable: null, cache: null)),
          Provider(
            create: (_) => BackgroundLocationService(
              platform: 0,
              version: '1',
              channel: _bg,
            ),
          ),
          Provider<EtagCacheStore?>.value(value: null),
          Provider<NetworkUsageStore?>.value(value: null),
          Provider<MapTileCache?>.value(value: null),
          ChangeNotifierProvider.value(value: ExperimentalSettings(store)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeveloperPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('Clear location track'));
    await tester.tap(find.text('Clear location track'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Clear location track'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Location track cleared'), findsOneWidget);
    expect(calls, contains('bg:clearTrack'));

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Clear cache'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cache cleared'), findsOneWidget);
    expect(calls, contains('storage:clearSystemHttpCache'));
  });

  testWidgets('storage rows, the usage chart, and copy all', (tester) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final durable = openMemoryDb();
    final cacheDb = openMemoryDb();
    addTearDown(durable.close);
    addTearDown(cacheDb.close);
    await EtagCacheStore.createSchema(durable);
    await NetworkUsageStore.createSchema(durable);
    await durable.execute(
      'CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)',
    );
    await durable.execute("INSERT INTO notes (body) VALUES ('hello')");
    await cacheDb.execute('CREATE TABLE blobs (id INTEGER PRIMARY KEY)');
    await cacheDb.execute('INSERT INTO blobs (id) VALUES (1)');

    final store = SettingsStore.inMemory();
    final etag = EtagCacheStore(durable);
    final usage = NetworkUsageStore(durable);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => NotificationService(store)),
          Provider.value(
            value: AppDatabase(durable: durable, cache: cacheDb),
          ),
          Provider(
            create: (_) => BackgroundLocationService(
              platform: 0,
              version: '1',
              channel: _bg,
            ),
          ),
          Provider<EtagCacheStore?>.value(value: etag),
          Provider<NetworkUsageStore?>.value(value: usage),
          Provider<MapTileCache?>.value(value: MapTileCache(etag)),
          ChangeNotifierProvider.value(value: ExperimentalSettings(store)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeveloperPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('notes'), findsOneWidget);
    expect(find.text('blobs'), findsOneWidget);
    expect(
      find.text('No traffic recorded yet — use the app and come back.'),
      findsOneWidget,
    );

    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') return null;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.tap(find.byIcon(Icons.copy_all_outlined));
    await tester.pump();
    await tester.pump();
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('a cache clear and a track clear that throw stay on the page', (
    tester,
  ) async {
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = openMemoryDb();
    addTearDown(db.close);
    await EtagCacheStore.createSchema(db);
    final store = SettingsStore.inMemory();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => NotificationService(store)),
          Provider.value(value: const AppDatabase(durable: null, cache: null)),
          Provider<BackgroundLocationService>.value(value: _ThrowingTrack()),
          Provider<EtagCacheStore?>.value(value: _ThrowingCache(db)),
          Provider<NetworkUsageStore?>.value(value: null),
          Provider<MapTileCache?>.value(value: null),
          ChangeNotifierProvider.value(value: ExperimentalSettings(store)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeveloperPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('Clear location track'));
    await tester.tap(find.text('Clear location track'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Clear location track'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Location track cleared'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Clear cache'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cache cleared'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ThrowingCache extends EtagCacheStore {
  _ThrowingCache(super.db);

  @override
  Future<void> clear() async {
    throw StateError('clear failed');
  }
}

class _ThrowingTrack extends BackgroundLocationService {
  _ThrowingTrack() : super(platform: 0, version: '1', channel: _bg);

  @override
  Future<void> clearTrack() async {
    throw StateError('track');
  }
}
