import 'package:dpip/app/router/notification_routes.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validRoutes = {
    AppRoutes.home,
    AppRoutes.events,
    AppRoutes.map,
    AppRoutes.earthquake,
    AppRoutes.more,
  };
  const knownGroups = {
    'group_eew',
    'group_eq',
    'group_info',
    'group_tsunami',
    'group_other',
  };

  test('every alert channel is in a known group and routes to a valid tab', () {
    for (final channel in NotificationChannels.channels) {
      // Non-alert service channels (e.g. `background`) have no group and aren't
      // navigation targets — they're excluded from the routing invariant.
      if (channel.channelGroupKey == null) continue;
      final key = channel.channelKey!;
      expect(
        NotificationChannels.groupOf(key),
        isIn(knownGroups),
        reason: 'channel $key has an unmapped group',
      );
      expect(
        routeForNotificationChannel(key),
        isIn(validRoutes),
        reason: 'channel $key resolves to an invalid route',
      );
    }
  });

  test('the groupless background service channel falls back home', () {
    expect(NotificationChannels.groupOf('background'), isNull);
    expect(routeForNotificationChannel('background'), AppRoutes.home);
  });

  test('routes each family to the expected screen', () {
    expect(
      routeForNotificationChannel('eew_alert-important-v2'),
      AppRoutes.earthquake,
    );
    expect(routeForNotificationChannel('eq-v2'), AppRoutes.earthquake);
    expect(
      routeForNotificationChannel('int_report-general-v2'),
      AppRoutes.earthquake,
    );
    expect(routeForNotificationChannel('report-general-v2'), AppRoutes.map);
    expect(routeForNotificationChannel('tsunami-important-v2'), AppRoutes.home);
    expect(
      routeForNotificationChannel('announcement-general-v2'),
      AppRoutes.home,
    );
  });

  test('an unknown or null channel falls back to home', () {
    expect(routeForNotificationChannel('does-not-exist'), AppRoutes.home);
    expect(routeForNotificationChannel(null), AppRoutes.home);
  });
}
