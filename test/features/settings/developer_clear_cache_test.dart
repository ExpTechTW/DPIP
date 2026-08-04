import 'dart:typed_data';

import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/features/settings/presentation/pages/developer_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late EtagCacheStore store;

  setUpAll(sqfliteFfiInit);

  const deviceInfo = MethodChannel('com.exptech.dpip/device_info');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'DPIP',
      packageName: 'com.exptech.dpip',
      version: '3.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          deviceInfo,
          (call) async => <String, dynamic>{
            'manufacturer': 'Test',
            'model': 'Test',
            'osVersion': '1.0',
          },
        );
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await EtagCacheStore.createSchema(db);
    await NetworkUsageStore.createSchema(db);
    store = EtagCacheStore(db);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceInfo, null);
    await db.close();
  });

  Future<Widget> subject() async {
    final prefs = Prefs(await SharedPreferences.getInstance());
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: NotificationService(prefs)),
        Provider<EtagCacheStore?>.value(value: store),
        Provider<NetworkUsageStore?>.value(value: NetworkUsageStore(db)),
        Provider<MapTileCache?>.value(value: MapTileCache(store)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeveloperPage(),
      ),
    );
  }

  testWidgets('clearing the cache empties the store', (tester) async {
    await store.writeBytes(
      'https://x/tile.webp',
      etag: 'W/"t"',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/webp',
    );
    expect((await store.stats()).rows, 1);

    await tester.pumpWidget(await subject());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.developerClearCache));
    await tester.pumpAndSettle();

    // Cancelling must not touch anything.
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect((await store.stats()).rows, 1);

    await tester.tap(find.text(l10n.developerClearCache));
    await tester.pumpAndSettle();
    // The dialog's confirm button carries the same label as the row.
    await tester.tap(find.text(l10n.developerClearCache).last);
    await tester.pumpAndSettle();

    expect((await store.stats()).rows, 0);
    expect(find.text(l10n.developerCacheCleared), findsOneWidget);
  });
}
