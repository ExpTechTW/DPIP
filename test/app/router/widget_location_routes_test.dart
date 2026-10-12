import 'package:dpip/app/router/widget_location_routes.dart';
import 'package:dpip/app/router/notification_routes.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/shared/navigation/widget_location_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegionStore regions;
  final directory = TownDirectory.fromJson({
    for (final code in ['407', '242'])
      code: {
        'city': 'Test',
        'town': code,
        'lat': 24.0,
        'lng': 121.0,
        'cityLevel': '市',
        'townLevel': '區',
      },
  });

  setUp(() {
    regions = RegionStore(SettingsStore.inMemory())
      ..addSaved('407')
      ..addSaved('242');
  });
  tearDown(() => regions.dispose());

  WidgetLocationLink? parse(String value) =>
      WidgetLocationLink.parse(Uri.parse('dpip:///home?widgetLocation=$value'));

  test('saved identifiers accept exactly three ASCII digits', () {
    for (final code in ['000', '100', '242', '407', '999']) {
      expect(parse('region%3A$code')?.identifier, 'region:$code');
    }
    for (final code in ['1', '10', '1000', '10000', '٤٠٧', '४०७', '４０７']) {
      expect(parse('region%3A$code'), isNull, reason: code);
    }
  });

  test('percent decoding selects the saved region by code after reorder', () {
    final link = parse('region%3A407')!;
    regions.reorderSaved(0, 1);
    expect(link.select(regions, directory), isTrue);
    expect(regions.selected, isA<SavedArea>());
    expect(regions.selectedCode, '407');
    expect(regions.selectedIndex, 3);
  });

  test('current location selects its area even without a GPS fix', () {
    regions.select(2);
    expect(parse('current-location')!.select(regions, directory), isTrue);
    expect(regions.selected, isA<CurrentArea>());
    expect(regions.selectedCode, isNull);
  });

  test('unknown, deleted and invalid directory regions keep the selection', () {
    regions.select(3);
    final original = regions.savedCodes;
    expect(parse('region%3A302')!.select(regions, directory), isFalse);
    expect(regions.savedCodes, original);
    final removed = parse('region%3A407')!;
    regions.removeSaved('407');
    expect(removed.select(regions, directory), isFalse);
    expect(regions.selectedCode, '242');
    regions.addSaved('999');
    expect(parse('region%3A999')!.select(regions, directory), isFalse);
    expect(regions.selectedCode, '242');
  });

  test('invalid, ambiguous and double encoded targets are rejected', () {
    for (final value in [
      '',
      'region%3A',
      'region%3A40',
      'region%3A4070',
      'region%3A４０７',
      'region%3A407%0A',
      'region%253A407',
      'region%3A407%26other%3D242',
      'nationwide',
      'region%3A407&widgetLocation=current-location',
    ]) {
      expect(parse(value), isNull, reason: value);
    }
    expect(WidgetLocationLink.parse(Uri.parse('/home')), isNull);
  });

  test('onboarding retains the latest request and consumes it only once', () {
    final routes = WidgetLocationRoutes();
    expect(
      routes.redirect(
        onboardingComplete: false,
        uri: Uri.parse('dpip:///home?widgetLocation=region%3A407'),
      ),
      '/onboarding',
    );
    routes.redirect(
      onboardingComplete: false,
      uri: Uri.parse('dpip:///home?widgetLocation=region%3A242'),
    );
    expect(
      routes.redirect(onboardingComplete: true, uri: Uri.parse('/onboarding')),
      '/home',
    );
    expect(routes.takePending()!.identifier, 'region:242');
    expect(routes.takePending(), isNull);
  });

  test(
    'identical taps are separate requests; plain navigation is unchanged',
    () {
      final routes = WidgetLocationRoutes();
      final uri = Uri.parse('dpip:///home?widgetLocation=region%3A407');
      routes.redirect(onboardingComplete: true, uri: uri);
      final first = routes.takePending();
      routes.redirect(onboardingComplete: true, uri: uri);
      expect(identical(first, routes.takePending()), isFalse);
      for (final path in ['/home', '/map', '/events']) {
        expect(
          routes.redirect(onboardingComplete: true, uri: Uri.parse(path)),
          isNull,
        );
      }
    },
  );

  test(
    'EEW navigation keeps its map destination while a Widget is pending',
    () {
      final routes = WidgetLocationRoutes();
      routes.redirect(
        onboardingComplete: true,
        uri: Uri.parse('dpip:///home?widgetLocation=region%3A407'),
      );
      final order = <String>[];
      routeNotificationTap(
        const NotificationTap(channelKey: 'eew_alert-important-v2'),
        focusMapLayer: (layer) => order.add(layer),
        navigate:
            (
              name, {
              Map<String, String> pathParameters = const {},
              Map<String, dynamic> queryParameters = const {},
              String? fragment,
              Object? extra,
            }) {
              order.add(name);
              expect(
                routes.redirect(
                  onboardingComplete: true,
                  uri: Uri.parse('/map'),
                ),
                isNull,
              );
            },
      );
      expect(order, ['monitor', 'map']);
      expect(routes.takePending()!.select(regions, directory), isTrue);
      expect(regions.selectedCode, '407');
      expect(routes.takePending(), isNull);
      expect(order.last, 'map');
    },
  );
}
