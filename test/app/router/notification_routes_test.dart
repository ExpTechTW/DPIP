import 'package:dpip/app/router/notification_routes.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validRoutes = {
    AppRoutes.home,
    AppRoutes.events,
    AppRoutes.map,
    AppRoutes.data,
    AppRoutes.earthquake,
    AppRoutes.eew,
    AppRoutes.more,
    AppRoutes.meshtastic,
  };
  // The routing table is keyed per channel, so a newly declared channel no
  // longer inherits a destination from its group. This is the test that makes
  // that safe: it fails on the first channel missing a row, which is the only
  // reason routing per channel is defensible at all.
  test('every declared channel has a row in the routing table', () {
    final declared = [
      for (final channel in NotificationChannels.channels) channel.channelKey!,
    ];
    final missing = [
      for (final key in declared)
        if (!notificationChannelRoutes.containsKey(key)) key,
    ];
    expect(
      missing,
      isEmpty,
      reason:
          'add these to notificationChannelRoutes in notification_routes.dart',
    );
  });

  // The mirror of the above: a row whose channel no longer exists is dead
  // weight that reads as coverage.
  test('the routing table has no row for a channel that was removed', () {
    final declared = {
      for (final channel in NotificationChannels.channels) channel.channelKey!,
    };
    final stale = [
      for (final key in notificationChannelRoutes.keys)
        if (!declared.contains(key)) key,
    ];
    expect(stale, isEmpty, reason: 'these channels no longer exist');
  });

  test('every channel resolves to a route the shell can actually show', () {
    for (final entry in notificationChannelRoutes.entries) {
      expect(
        entry.value,
        isIn(validRoutes),
        reason: 'channel ${entry.key} resolves to an invalid route',
      );
    }
  });

  test('the background service channel resolves without a warning', () {
    // Not an alert and never tapped, but it is a declared channel, so it needs
    // a row or the coverage test above fails.
    expect(notificationChannelRoutes['background'], AppRoutes.home);
  });

  test('routes each family to the expected screen', () {
    // 地震速報 opens 強震監視器, which is an overlay on the map tab rather than a
    // screen of its own — see the map-layer test below for the other half.
    expect(
      routeForNotificationChannel('eew_alert-important-v2'),
      AppRoutes.map,
    );
    // The intra-family split: 震度速報 is a live broadcast and opens the
    // monitor, while a 地震報告 is a finished record and opens the list.
    expect(routeForNotificationChannel('eq-v2'), AppRoutes.map);
    expect(
      routeForNotificationChannel('report-general-v2'),
      AppRoutes.earthquake,
    );
    expect(routeForNotificationChannel('tsunami-important-v2'), AppRoutes.home);
    expect(
      routeForNotificationChannel('announcement-general-v2'),
      AppRoutes.home,
    );
  });

  // The bug this guards: a server push is rendered from awesome's own wire
  // format, where the channel is a model field and `payload` is absent. Reading
  // the channel from the payload alone left every remote tap with a null
  // channel, and every remote tap landed on Home.
  test('a push tap carries its channel on the action, not the payload', () {
    final tap = NotificationTap.fromData(
      null,
      channelKey: 'eew_alert-important-v2',
    );
    expect(tap.channelKey, 'eew_alert-important-v2');
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.map);
  });

  test('a locally displayed tap still routes off its payload', () {
    // Notifications this app posts itself do carry `channel` — the service puts
    // it there — and must keep working with no action channel supplied.
    final tap = NotificationTap.fromData({
      'channel': 'report-general-v2',
      'id': '42',
    });
    expect(tap.channelKey, 'report-general-v2');
    expect(tap.id, '42');
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.earthquake);
  });

  test('the action channel wins over a stale payload channel', () {
    final tap = NotificationTap.fromData({
      'channel': 'announcement-general-v2',
    }, channelKey: 'mesh_message');
    expect(tap.channelKey, 'mesh_message');
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.meshtastic);
  });

  // What the device actually delivers: awesome hands the tap a payload of
  // exactly one key, `content`, holding the producer's JSON. The id lives in
  // there and nowhere else.
  test('a push tap unpacks the id out of the nested content', () {
    final tap = NotificationTap.fromData({
      'content':
          '{"id":1897213924,"channelKey":"int_report-general-v2",'
          '"body":"…","notificationLayout":"BigText"}',
    }, channelKey: 'int_report-general-v2');
    expect(tap.channelKey, 'int_report-general-v2');
    expect(tap.id, '1897213924');
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.home);
  });

  test('a malformed content string still routes', () {
    final tap = NotificationTap.fromData({
      'content': 'not json',
    }, channelKey: 'report-general-v2');
    expect(tap.channelKey, 'report-general-v2');
    expect(tap.id, isNull);
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.earthquake);
  });

  test('every url-destination channel also has a route to fall back to', () {
    for (final key in notificationChannelUrls.keys) {
      expect(
        notificationChannelRoutes,
        contains(key),
        reason: '$key opens a URL but has nowhere to land if it will not open',
      );
      expect(Uri.tryParse(notificationChannelUrls[key]!)?.hasScheme, isTrue);
    }
  });

  test('an announcement tap opens the web, and does not navigate', () {
    final opened = <Uri>[];
    final navigated = <String>[];
    routeNotificationTap(
      const NotificationTap(channelKey: 'announcement-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) => navigated.add(name),
      launch: (url) async {
        opened.add(url);
        return true;
      },
    );

    expect(opened, [Uri.parse('https://announcement.exptech.com.tw/')]);
    expect(navigated, isEmpty);
  });

  test('an announcement tap that will not open falls back into the app', () {
    final navigated = <String>[];
    routeNotificationTap(
      const NotificationTap(channelKey: 'announcement-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) => navigated.add(name),
      launch: (url) async => false,
    );

    // The launch is async, so the fallback lands after the microtask drains.
    return Future<void>.delayed(Duration.zero, () {
      expect(navigated, [AppRoutes.home]);
    });
  });

  test('a launcher that throws still lands the tap somewhere', () {
    final navigated = <String>[];
    routeNotificationTap(
      const NotificationTap(channelKey: 'announcement-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) => navigated.add(name),
      launch: (url) async => throw Exception('no browser'),
    );

    return Future<void>.delayed(Duration.zero, () {
      expect(navigated, [AppRoutes.home]);
    });
  });

  test('a report tap with a target opens that report, not the list', () {
    final navigated = <({String name, Map<String, String> params})>[];
    routeNotificationTap(
      NotificationTap.fromData({
        'content':
            '{"id":123,"channelKey":"report-general-v2",'
            '"extra":{"reportId":"115058-2026-0827-054720"}}',
      }, channelKey: 'report-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) => navigated.add((name: name, params: pathParameters)),
    );

    // Records compare their fields with `==`, and two equal Maps are not
    // identical, so the pair is checked apart rather than as one value.
    expect(navigated, hasLength(1));
    expect(navigated.single.name, AppRoutes.earthquakeReport);
    expect(navigated.single.params, {'id': '115058-2026-0827-054720'});
  });

  test('a report tap without a target still opens the list', () {
    final navigated = <String>[];
    routeNotificationTap(
      NotificationTap.fromData({
        'content': '{"id":123,"channelKey":"report-general-v2"}',
      }, channelKey: 'report-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) => navigated.add(name),
    );

    expect(navigated, [AppRoutes.earthquake]);
  });

  test('an empty target is treated as absent', () {
    expect(
      detailFor(
        const NotificationTap(
          channelKey: 'report-general-v2',
          data: {'reportId': ''},
        ),
      ),
      isNull,
    );
  });

  test('the report id never collides with the notification id', () {
    // The producer sends both; they are different things and different keys.
    final tap = NotificationTap.fromData({
      'content':
          '{"id":123456,"channelKey":"report-general-v2",'
          '"extra":{"reportId":"115058-2026-0827-054720"}}',
    }, channelKey: 'report-general-v2');
    expect(tap.id, '123456');
    expect(tap.data[notificationTargetKey], '115058-2026-0827-054720');
  });

  test('every detail channel also has a list route to fall back to', () {
    for (final key in notificationChannelDetailRoutes.keys) {
      expect(
        notificationChannelRoutes,
        contains(key),
        reason: '$key has a detail route but nowhere to land without a target',
      );
    }
  });

  test('extra wins over a model field of the same name', () {
    // The whole reason extra is a namespace: `id` belongs to awesome's model,
    // and a producer that puts one in extra means the app's.
    final tap = NotificationTap.fromData({
      'content': '{"id":123,"channelKey":"eq-v2","extra":{"id":"mine"}}',
    }, channelKey: 'eq-v2');
    expect(tap.id, 'mine');
  });

  test('extra is accepted as a JSON string as well as an object', () {
    final tap = NotificationTap.fromData({
      'content':
          '{"channelKey":"report-general-v2",'
          '"extra":"{\\"reportId\\":\\"115058-2026-0827-054720\\"}"}',
    }, channelKey: 'report-general-v2');
    expect(tap.data[notificationTargetKey], '115058-2026-0827-054720');
  });

  test('neither container leaks into the data map under its own name', () {
    final tap = NotificationTap.fromData({
      'content': '{"channelKey":"eq-v2","extra":{"a":"1"}}',
    }, channelKey: 'eq-v2');
    expect(tap.data.containsKey('content'), isFalse);
    expect(tap.data.containsKey('extra'), isFalse);
    expect(tap.data['a'], '1');
  });

  test('a malformed extra does not stop the tap routing', () {
    final tap = NotificationTap.fromData({
      'content': '{"channelKey":"report-general-v2","extra":"not json"}',
    }, channelKey: 'report-general-v2');
    expect(tap.data[notificationTargetKey], isNull);
    expect(routeForNotificationChannel(tap.channelKey), AppRoutes.earthquake);
  });

  // The iOS wire shape: awesome parses `content` into its model and keeps only
  // the fields it knows, so application data has to ride in `payload` — the
  // slot the model reserves for it. A custom key is dropped, and the tap
  // arrives with an empty payload.
  test('a report tap reads its target out of content.payload', () {
    final tap = NotificationTap.fromData({
      'content':
          '{"id":123,"channelKey":"report-general-v2",'
          '"payload":{"reportId":"115058-2026-0827-054720"}}',
    }, channelKey: 'report-general-v2');
    expect(tap.data[notificationTargetKey], '115058-2026-0827-054720');
    expect(tap.id, '123');
  });

  test('a target that already sits flat in the payload still works', () {
    // What iOS hands over once awesome has done the parsing: the model's
    // payload map, delivered directly with no `content` wrapper left.
    final tap = NotificationTap.fromData({
      'reportId': '115058-2026-0827-054720',
    }, channelKey: 'report-general-v2');
    expect(tap.data[notificationTargetKey], '115058-2026-0827-054720');
  });

  test('an unknown or null channel falls back to home', () {
    expect(routeForNotificationChannel('does-not-exist'), AppRoutes.home);
    expect(routeForNotificationChannel(null), AppRoutes.home);
  });

  test('routeNotificationTap navigates to the resolved route', () {
    final named = <String>[];
    void record(
      String name, {
      Map<String, String> pathParameters = const {},
      Map<String, dynamic> queryParameters = const {},
      String? fragment,
      Object? extra,
    }) {
      named.add(name);
    }

    // EEW channel → the map tab, where 強震監視器 lives.
    routeNotificationTap(
      const NotificationTap(channelKey: 'eew_alert-important-v2'),
      navigate: record,
    );
    // Report family → the report list tab.
    routeNotificationTap(
      const NotificationTap(channelKey: 'report-general-v2'),
      navigate: record,
    );
    // An unmapped channel falls back to home rather than throwing.
    routeNotificationTap(
      const NotificationTap(channelKey: 'does-not-exist'),
      navigate: record,
    );

    expect(named, [AppRoutes.map, AppRoutes.earthquake, AppRoutes.home]);
  });

  // Half of an EEW tap's destination is the route; the other half is which of
  // the map's fourteen overlays it lands on. Routing alone would drop the user
  // on whatever the session was last looking at.
  test('an EEW tap asks the map for 強震監視器, before it navigates', () {
    final order = <String>[];
    void record(
      String name, {
      Map<String, String> pathParameters = const {},
      Map<String, dynamic> queryParameters = const {},
      String? fragment,
      Object? extra,
    }) => order.add('go:$name');

    routeNotificationTap(
      const NotificationTap(channelKey: 'eew_alert-important-v2'),
      navigate: record,
      focusMapLayer: (layerId) => order.add('layer:$layerId'),
    );

    // The map consumes one pending overlay per open, so the request has to be
    // waiting before the tab is shown, not queued after it.
    expect(order, ['layer:$monitorMapLayerId', 'go:${AppRoutes.map}']);
  });

  test('a channel with no overlay of its own leaves the map alone', () {
    final focused = <String>[];
    routeNotificationTap(
      const NotificationTap(channelKey: 'report-general-v2'),
      navigate: (
        name, {
        Map<String, String> pathParameters = const {},
        Map<String, dynamic> queryParameters = const {},
        String? fragment,
        Object? extra,
      }) {},
      focusMapLayer: focused.add,
    );
    expect(focused, isEmpty);
  });

  // The id is a literal in `app/router` because that layer must not import a
  // feature's presentation code. This is what keeps the literal honest.
  test('every mapped overlay id is one the map actually offers', () {
    expect(RtsMapLayer.layerId, monitorMapLayerId);
    for (final id in notificationChannelMapLayers.values) {
      expect(id, monitorMapLayerId);
    }
  });
}
