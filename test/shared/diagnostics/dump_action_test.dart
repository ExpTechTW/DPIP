/// The one-tap dump is what gets pasted into a bug report. Cancelling must
/// upload nothing, a refused paste must say so, and a link has to land on
/// the clipboard before the dialog can be dismissed.
library;

import 'dart:io';

import 'package:dpip/core/diagnostics/dump_uploader.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/diagnostics/dump_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';

const _bg = MethodChannel('test/dump_background_location');
const _device = MethodChannel('com.exptech.dpip/device_info');
const _storage = MethodChannel('com.exptech.dpip/storage_scan');

class _Paths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;
}

class _Uploader implements DumpUploader {
  _Uploader(this._url, {this.throwOnUpload = false});

  final String? _url;
  final bool throwOnUpload;
  String? uploaded;

  @override
  Future<String?> upload(String content) async {
    uploaded = content;
    if (throwOnUpload) throw StateError('paste down');
    return _url;
  }
}

const _platform = SystemChannels.platform;
String? _clipboard;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    PathProviderPlatform.instance = _Paths();
    PackageInfo.setMockInitialValues(
      appName: 'DPIP',
      packageName: 'com.exptech.dpip',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    messenger.setMockMethodCallHandler(_device, (call) async {
      return <String, Object?>{
        'manufacturer': 'Apple',
        'model': 'TestPhone',
        'osVersion': '26',
      };
    });
    messenger.setMockMethodCallHandler(_storage, (_) async => null);
    messenger.setMockMethodCallHandler(_bg, (call) async {
      if (call.method != 'diagnostics') return null;
      return <String, Object?>{
        'enabled': true,
        'armed': true,
        'centreLat': 25.033,
        'centreLng': 121.565,
      };
    });
    messenger.setMockMethodCallHandler(_platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        _clipboard = (call.arguments as Map)['text'] as String?;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': _clipboard};
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_device, null);
    messenger.setMockMethodCallHandler(_storage, null);
    messenger.setMockMethodCallHandler(_bg, null);
    messenger.setMockMethodCallHandler(_platform, null);
    _clipboard = null;
  });

  Future<({_Uploader uploader, ValueNotifier<bool?> result})> open(
    WidgetTester tester,
    _Uploader uploader,
  ) async {
    final result = ValueNotifier<bool?>(null);
    addTearDown(result.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DumpUploader>.value(value: uploader),
          Provider(
            create: (_) => NotificationService(SettingsStore.inMemory()),
          ),
          Provider<AppDatabase>.value(
            value: const AppDatabase(durable: null, cache: null),
          ),
          Provider(
            create: (_) => BackgroundLocationService(
              platform: 0,
              version: '1',
              channel: _bg,
            ),
          ),
          Provider<EtagCacheStore?>.value(value: null),
          Provider<NetworkUsageStore?>.value(value: null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result.value = await runDiagnosticsDump(context);
                },
                child: const Text('dump'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('dump'));
    await tester.pumpAndSettle();
    return (uploader: uploader, result: result);
  }

  testWidgets('cancel uploads nothing', (tester) async {
    final opened = await open(tester, _Uploader('https://example.invalid/a'));
    final l10n = AppLocalizations.of(tester.element(find.text('dump')));
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(opened.result.value, isFalse);
    expect(opened.uploader.uploaded, isNull);
  });

  testWidgets('a missing link is a failure, and a throw is too', (
    tester,
  ) async {
    final missing = await open(tester, _Uploader(null));
    final l10n = AppLocalizations.of(tester.element(find.text('dump')));
    await tester.tap(find.text(l10n.dumpUpload));
    await tester.pumpAndSettle();
    expect(missing.result.value, isFalse);
    expect(find.text(l10n.dumpUploadFailed), findsOneWidget);

    final broken = await open(
      tester,
      _Uploader('https://example.invalid/a', throwOnUpload: true),
    );
    await tester.tap(find.text(l10n.dumpUpload));
    await tester.pumpAndSettle();
    expect(broken.result.value, isFalse);
  });

  testWidgets('a link is copied, and consent keeps the centre', (tester) async {
    final opened = await open(
      tester,
      _Uploader('https://example.invalid/dump'),
    );
    final l10n = AppLocalizations.of(tester.element(find.text('dump')));
    await tester.tap(find.text(l10n.dumpUpload));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(opened.uploader.uploaded, contains('Centred on: null'));
    expect(find.text('https://example.invalid/dump'), findsOneWidget);
    expect(
      (await Clipboard.getData('text/plain'))?.text,
      'https://example.invalid/dump',
    );
    await tester.tap(find.text(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(opened.result.value, isTrue);

    final consented = await open(
      tester,
      _Uploader('https://example.invalid/full'),
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(l10n.dumpUpload));
    await tester.pumpAndSettle();
    expect(consented.uploader.uploaded, contains('25.0330, 121.5650'));
    await tester.tap(find.text(l10n.commonClose));
    await tester.pumpAndSettle();
  });
}
