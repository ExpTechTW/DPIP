import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/maps_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records every URL handed to the platform so a test can assert the deep link
/// was actually opened — the exact thing the original picker forgot to do.
class _RecordingLauncher extends UrlLauncherPlatform {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    return true;
  }
}

void main() {
  const target = MapLaunchTarget(lat: 25.0330, lng: 121.5654, label: '台北市');
  const bare = MapLaunchTarget(lat: 25.0330, lng: 121.5654);

  group('mapsAppUrl', () {
    test('google with a label pins the label at the exact point', () {
      final url = Uri.parse(mapsAppUrl(MapApp.google, target));
      expect(url.host, 'www.google.com');
      expect(url.queryParameters['query'], '25.033,121.5654(台北市)');
    });

    test('google without a label uses the bare coordinate', () {
      final url = Uri.parse(mapsAppUrl(MapApp.google, bare));
      expect(url.queryParameters['query'], '25.033,121.5654');
    });

    test('apple carries q, ll and z so the map frames the point', () {
      final url = Uri.parse(mapsAppUrl(MapApp.apple, bare));
      expect(url.host, 'maps.apple.com');
      expect(url.queryParameters['q'], '25.033,121.5654');
      expect(url.queryParameters['ll'], '25.033,121.5654');
      expect(url.queryParameters['z'], '17');
    });
  });

  group('MapApp.ofPlatform', () {
    test('iOS and macOS default to Apple Maps', () {
      expect(MapApp.ofPlatform(TargetPlatform.iOS), MapApp.apple);
      expect(MapApp.ofPlatform(TargetPlatform.macOS), MapApp.apple);
    });

    test('everything else defaults to Google Maps', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(MapApp.ofPlatform(platform), MapApp.google);
      }
    });
  });

  group('callPhoneNumber', () {
    test('dials a tel: URI stripped to dialler-safe characters', () async {
      final launcher = _RecordingLauncher();
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      expect(await callPhoneNumber('02-1234 5678'), isTrue);
      expect(launcher.launched.single, 'tel:0212345678');
    });

    test(
      'keeps plus, hash and star for extensions and international',
      () async {
        final launcher = _RecordingLauncher();
        final original = UrlLauncherPlatform.instance;
        UrlLauncherPlatform.instance = launcher;
        addTearDown(() => UrlLauncherPlatform.instance = original);

        expect(await callPhoneNumber('+886 9 1234 5678 #5'), isTrue);
        expect(launcher.launched.single, 'tel:+886912345678#5');
      },
    );

    test('never launches when nothing dialler-safe remains', () async {
      final launcher = _RecordingLauncher();
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      expect(await callPhoneNumber('(none)'), isFalse);
      expect(launcher.launched, isEmpty);
    });
  });

  group('pickAndOpenMapApp', () {
    testWidgets('opens the chosen app after the picker returns it', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      const target = MapLaunchTarget(lat: 25.0330, lng: 121.5654);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => pickAndOpenMapApp(context, target),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // The test platform defaults to Android, so Google Maps is the
      // 預設-marked first row and Apple Maps the plain second one.
      await tester.tap(find.text('Apple Maps'));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1));
      expect(
        Uri.parse(launcher.launched.single).host,
        'maps.apple.com',
        reason:
            'the picker must hand the chosen app to the OS, not just '
            'dismiss itself',
      );
    });

    testWidgets('a failed open surfaces a snackbar', (tester) async {
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _DecliningLauncher();
      addTearDown(() => UrlLauncherPlatform.instance = original);

      const target = MapLaunchTarget(lat: 25.0330, lng: 121.5654);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => pickAndOpenMapApp(context, target),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple Maps'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open Apple Maps'), findsOneWidget);
    });
  });
}

class _DecliningLauncher extends _RecordingLauncher {
  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async => false;
}
