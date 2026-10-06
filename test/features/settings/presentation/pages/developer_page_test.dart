/// The developer page is what gets pasted into a bug report. A version row
/// that never unlocks, or a clear that runs without a confirm, would either
/// hide the experimental menu or wipe the cache by accident.
library;

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
}
