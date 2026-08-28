import 'dart:async';

import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL outside the app. Injectable so tests never reach the browser.
typedef NotificationUrlLauncher = Future<bool> Function(Uri url);

/// Asks the map tab to open on a given `MapLayer.id` when it next appears.
///
/// Injected rather than reached for: this function has no `BuildContext`, and
/// the hand-off it drives lives in the widget tree. `app.dart` supplies the
/// real one; a test supplies a recorder.
typedef NotificationMapFocus = void Function(String layerId);

/// The slice of the router a notification tap needs — [GoRouter.goNamed].
typedef NotificationRouteNavigator = void Function(
  String name, {
  Map<String, String> pathParameters,
  Map<String, dynamic> queryParameters,
  String? fragment,
  Object? extra,
});

/// Single owner of notification → destination: [NotificationTaps] carries the
/// tap intent and calls [routeNotificationTap] once the router is live
/// (replaying a cold-start tap through `NotificationTaps.drainPending`). No
/// widget hosts this logic.
///
/// [navigate] is injectable for tests; it defaults to the app router's
/// [GoRouter.goNamed].
void routeNotificationTap(
  NotificationTap tap, {
  NotificationRouteNavigator? navigate,
  NotificationUrlLauncher? launch,
  NotificationMapFocus? focusMapLayer,
}) {
  final go = navigate ?? appRouter.goNamed;
  Log.info(
    'Notification route: channel=${tap.channelKey} '
    'target=${tap.data[notificationTargetKey]} keys=${tap.data.keys.toList()}',
  );
  final url = notificationChannelUrls[tap.channelKey];
  if (url != null) {
    unawaited(_openExternally(tap, url, go, launch ?? _launch));
    return;
  }
  final detail = detailFor(tap);
  if (detail != null) {
    Log.info(
      'Notification tap: channel=${tap.channelKey} -> ${detail.name} '
      '${detail.pathParameters}',
    );
    go(detail.name, pathParameters: detail.pathParameters);
    return;
  }
  final route = routeForNotificationChannel(tap.channelKey);
  // Says *why* it is the list rather than an item, because "went to the list"
  // is what both a channel with no detail route and a missing target look like.
  final reason = notificationChannelDetailRoutes.containsKey(tap.channelKey)
      ? 'no $notificationTargetKey in payload'
      : 'channel has no detail route';
  // Before the navigation, not after: the map consumes the pending overlay on
  // the first frame it is ready, and a request queued after that frame waits
  // for the *next* time the tab opens.
  final layerId = notificationChannelMapLayers[tap.channelKey];
  if (layerId != null) {
    Log.info('Notification tap: channel=${tap.channelKey} -> layer=$layerId');
    focusMapLayer?.call(layerId);
  }
  Log.info(
    'Notification tap: channel=${tap.channelKey} -> route=$route ($reason)',
  );
  go(route);
}

/// Channels whose payload can name one specific item, and the route that shows
/// it. The item's identifier travels under [notificationTargetKey].
///
/// Only the earthquake-report channels do this today. The push producer sends
/// the report id — a string like `115058-2026-0827-054720` — and the tap opens
/// that report rather than the list it sits in.
///
/// Deliberately **not** the notification's own `id`. That one is
/// awesome_notifications' 32-bit replace/dedupe handle, and a report id is a
/// long string; sharing the key would have the report id truncated into a
/// notification id, or the whole notification dropped for being out of range.
const Map<String, String> notificationChannelDetailRoutes = {
  'report-general-v2': AppRoutes.earthquakeReport,
  'report-silence-v2': AppRoutes.earthquakeReport,
};

/// Channels whose destination is a specific map overlay, and its `MapLayer.id`.
///
/// The map tab is one route for fourteen overlays, and it keeps whichever one
/// the session was last on. So a route is not a destination here — an EEW tap
/// that arrives while the user was reading radar would open radar. The overlay
/// is handed over the same way every other in-app "open this on the map" does
/// (`MapCameraHandoff`), as a one-shot the map consumes when it is ready.
const Map<String, String> notificationChannelMapLayers = {
  'eew_alert-important-v2': monitorMapLayerId,
  'eew_alert-general-v2': monitorMapLayerId,
  'eew_alert-silent-v2': monitorMapLayerId,
  'eew-important-v2': monitorMapLayerId,
  'eew-general-v2': monitorMapLayerId,
  'eew-silence-v2': monitorMapLayerId,
  'eq-v2': monitorMapLayerId,
};

/// `RtsMapLayer.id` — 強震監視器. A literal because `app/router` must not import
/// a feature's presentation layer; `notification_routes_test` pins the two
/// together.
const String monitorMapLayerId = 'monitor';

/// The payload key naming the item a tap should open.
const String notificationTargetKey = 'reportId';

/// The specific-item destination for [tap], or null to fall back to the list.
///
/// Null whenever anything is missing — an older producer that sends no target,
/// an empty string, a channel with no detail route. A notification that says
/// only "a report arrived" is still worth opening; it just opens the list.
({String name, Map<String, String> pathParameters})? detailFor(
  NotificationTap tap,
) {
  final route = notificationChannelDetailRoutes[tap.channelKey];
  if (route == null) return null;
  final target = tap.data[notificationTargetKey];
  if (target == null || target.isEmpty) return null;
  // The route's path is `:id` — see `earthquakeReportPath`.
  return (name: route, pathParameters: {'id': target});
}

Future<bool> _launch(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Sends the tap to the browser, falling back into the app if it will not go.
///
/// The fallback is the point. A device with no browser, a URL the OS refuses,
/// a launcher that throws mid-cold-start — any of those would otherwise leave
/// the tap doing nothing at all, which is indistinguishable from the app
/// having ignored it. The channel keeps its row in [notificationChannelRoutes]
/// precisely so there is somewhere to land.
Future<void> _openExternally(
  NotificationTap tap,
  String url,
  NotificationRouteNavigator go,
  NotificationUrlLauncher launch,
) async {
  Log.info('Notification tap: channel=${tap.channelKey} -> url=$url');
  var opened = false;
  try {
    opened = await launch(Uri.parse(url));
  } catch (error) {
    Log.warning('Notification tap: could not open $url — $error');
  }
  if (opened) return;
  final route = routeForNotificationChannel(tap.channelKey);
  Log.warning('Notification tap: $url did not open, falling back to $route');
  go(route);
}

/// Channels whose tap belongs outside the app.
///
/// A tap here opens the browser instead of navigating, and the entry wins over
/// [notificationChannelRoutes] — which still carries a row for the same
/// channel, as the fallback for when the browser will not open. Two tables
/// rather than one destination union: the union would be the tidier type, but
/// every channel would then have to say which kind it is, to express something
/// exactly one channel does.
const Map<String, String> notificationChannelUrls = {
  // 公告 lives on the web and has no in-app screen. Home is its fallback.
  'announcement-general-v2': 'https://announcement.exptech.com.tw/',
};

/// Every channel's destination, one row each.
///
/// Keyed by `channelKey` rather than derived from the channel's group. The
/// group was the shorter table — six rows instead of twenty-four — and it
/// carried a property this one does not: a newly declared channel routed
/// correctly on the strength of its group, with no edit here. Routing per
/// channel buys the ability to send two channels in the same group to
/// different screens, and pays for it by making every new channel a row that
/// somebody has to remember.
///
/// Nobody has to remember: `notification_routes_test.dart` walks
/// [NotificationChannels.channels] and fails on the first key missing from this
/// map. A forgotten row is a red test, not a tap that quietly lands on Home.
///
/// Grouped by subject for reading only — the lookup is exact, so order and
/// grouping carry no meaning and no prefix can shadow another.
const Map<String, String> notificationChannelRoutes = {
  // 地震速報 — 強震監視器 on the map, where the countdown, the wavefront and
  // the shaking all are. The overlay comes from [notificationChannelMapLayers];
  // the route alone would land on whichever layer the session last used.
  'eew_alert-important-v2': AppRoutes.map,
  'eew_alert-general-v2': AppRoutes.map,
  'eew_alert-silent-v2': AppRoutes.map,
  'eew-important-v2': AppRoutes.map,
  'eew-general-v2': AppRoutes.map,
  'eew-silence-v2': AppRoutes.map,
  'eq-v2': AppRoutes.map,
  'int_report-general-v2': AppRoutes.home, // 需要 ID
  'int_report-silence-v2': AppRoutes.home, // 需要 ID
  // 地震 — the report list. Detail-by-id comes later; the tap already carries
  // the id, so that is a change to `routeNotificationTap`, not to this table.
  'report-general-v2': AppRoutes.earthquake, // 需要 ID
  'report-silence-v2': AppRoutes.earthquake, // 需要 ID
  // 天氣 — no dedicated screen yet, so Home, which surfaces active events.
  'thunderstorm-important-v2': AppRoutes.home, // 需要 ID
  'thunderstorm-general-v2': AppRoutes.home, // 需要 ID
  'weather_major-important-v2': AppRoutes.home, // 需要 ID
  'weather_minor-general-v2': AppRoutes.home, // 需要 ID
  'evacuation_major-important-v2': AppRoutes.home, // 需要 ID
  'evacuation_minor-general-v2': AppRoutes.home, // 需要 ID
  // 海嘯 — same, until a tsunami screen exists.
  'tsunami-important-v2': AppRoutes.home, // 需要 ID
  'tsunami-general-v2': AppRoutes.home, // 需要 ID
  'tsunami-silent-v2': AppRoutes.home, // 需要 ID
  // LoRa 網狀網路
  'mesh_message': AppRoutes.meshtastic,
  'mesh_node': AppRoutes.meshtastic,

  // 其他
  'announcement-general-v2': AppRoutes.home,

  // Not an alert and not a navigation target: the silent service channel for
  // background work. It is here so that it resolves without logging the
  // "unmapped" warning every time something inspects it.
  'background': AppRoutes.home,
};

/// Resolves a tapped notification's channel to a destination route.
///
/// An exact lookup in [notificationChannelRoutes]. An unknown key is logged and
/// sent Home — a tap must always land somewhere, but never silently.
String routeForNotificationChannel(String? channelKey) {
  if (channelKey == null) return _unmapped(channelKey);
  return notificationChannelRoutes[channelKey] ?? _unmapped(channelKey);
}

String _unmapped(String? channelKey) {
  Log.warning('Notification channel not mapped to a route: $channelKey');
  return AppRoutes.home;
}
