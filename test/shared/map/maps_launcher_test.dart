import 'package:dpip/shared/map/maps_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
