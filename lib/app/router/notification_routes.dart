import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/shared/navigation/app_routes.dart';

/// Resolves a tapped notification's channel to a destination route.
///
/// Declarative and group-driven (via [NotificationChannels.groupOf]) instead of
/// a hand-ordered `startsWith` chain: a new channel routes by its group with no
/// change here, and an unmapped one is logged, not silently sent Home. Detail
/// routes (a specific report/event by id) come later; this picks the tab and the
/// tap already carries the id.
String routeForNotificationChannel(String? channelKey) {
  if (channelKey == null) return _unmapped(channelKey);

  // The only intra-group split: report detail lands on the map, while the rest
  // of the earthquake group (int_report / eq) is the monitor.
  if (channelKey.startsWith('report')) return AppRoutes.map;

  return switch (NotificationChannels.groupOf(channelKey)) {
    'group_eew' || 'group_eq' => AppRoutes.earthquake,
    'group_info' || 'group_tsunami' || 'group_other' => AppRoutes.home,
    _ => _unmapped(channelKey),
  };
}

String _unmapped(String? channelKey) {
  Log.warning('Notification channel not mapped to a route: $channelKey');
  return AppRoutes.home;
}
