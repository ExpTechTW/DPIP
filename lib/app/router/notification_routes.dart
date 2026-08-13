import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/shared/navigation/app_routes.dart';

/// The slice of the router a notification tap needs — [GoRouter.goNamed].
typedef NotificationRouteNavigator = void Function(
  String name, {
  Map<String, String> pathParameters,
  Map<String, dynamic> queryParameters,
  String? fragment,
  Object? extra,
});

/// Single owner of notification → destination, mirroring the legacy
/// `notify.dart` tap table in one file: [NotificationTaps] carries the tap
/// intent and calls [routeNotificationTap] once the router is live (replaying a
/// cold-start tap through [NotificationTaps.drainPending]). The channel
/// resolves to a route name via the declarative group table below, then the
/// router navigates — no widget hosts this logic, so adding an alert family is
/// one row in the table and nothing else.
///
/// [navigate] is injectable for tests; it defaults to the app router's
/// [GoRouter.goNamed].
void routeNotificationTap(
  NotificationTap tap, {
  NotificationRouteNavigator? navigate,
}) {
  (navigate ?? appRouter.goNamed)(routeForNotificationChannel(tap.channelKey));
}

/// Resolves a tapped notification's channel to a destination route.
///
/// Declarative and group-driven (via [NotificationChannels.groupOf]) instead of
/// a hand-ordered `startsWith` chain: a new channel routes by its group with no
/// change here, and an unmapped one is logged, not silently sent Home. Detail
/// routes (a specific report/event by id) come later; this picks the tab and the
/// tap already carries the id.
String routeForNotificationChannel(String? channelKey) {
  if (channelKey == null) return _unmapped(channelKey);

  // The only intra-group split: report detail lands on the report list for now,
  // while EEW taps open the live monitor.
  if (channelKey.startsWith('report')) return AppRoutes.earthquake;

  return switch (NotificationChannels.groupOf(channelKey)) {
    'group_eew' => AppRoutes.eew,
    'group_eq' => AppRoutes.earthquake,
    'group_info' || 'group_tsunami' || 'group_other' => AppRoutes.home,
    _ => _unmapped(channelKey),
  };
}

String _unmapped(String? channelKey) {
  Log.warning('Notification channel not mapped to a route: $channelKey');
  return AppRoutes.home;
}
