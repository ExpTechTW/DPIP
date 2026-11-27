/// Routes that open only while a setting allows them, and the signal that
/// re-checks them when that setting changes.
///
/// Hiding the way in is not enough. A route stays reachable by URL — iOS
/// registers the `dpip` scheme and Flutter's deep linking is on, and on Android
/// an explicit intent carrying a URI reaches the exported launcher activity
/// even without an intent filter — and a page opened while the setting allowed
/// it outlives the setting. So the route itself refuses, in a route-level
/// `redirect`, and [routeGateRefresh] makes the router run that redirect again
/// the moment the setting flips.
library;

import 'package:dpip/core/platform/device_sensors.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The seismometer opens only when the Data tab would list it: its
/// Experimental features switch is on and the device is known to have an
/// accelerometer. Otherwise a location that reaches the page lands on the Data
/// tab's root.
///
/// The sensor is part of the test because the switch can be on where nothing
/// can turn it off: a setting restored from a backup onto a device without an
/// accelerometer, whose Experimental features page does not offer the option.
/// An accelerometer still being asked about counts as none, as on the Data
/// tab, so a link that lands in the first moments of a launch opens the tab.
///
/// This covers a link, and a page already open when the switch goes off: the
/// refresh re-runs this for the location on screen, and switching back to the
/// Data tab restores that branch's location through it. Both only work because
/// the Data tab opens the page with `go`, so the location names it — a `push`
/// leaves the location at `/data`, and nothing here would ever see the page.
String? seismometerRedirect(BuildContext context, GoRouterState state) =>
    context.read<ExperimentalSettings>().seismometerEnabled &&
        context.read<DeviceSensors>().has(DeviceSensor.accelerometer)
    ? null
    : state.namedLocation(AppRoutes.data);

/// Fires when a switch a gate reads flips (today only the seismometer's), so
/// the router re-runs its redirects. bootstrap points it at the app's
/// [ExperimentalSettings] with [RouteGateRefresh.watch].
final RouteGateRefresh routeGateRefresh = RouteGateRefresh();

/// Re-announces the gated switches of one [ExperimentalSettings].
///
/// Only a flip of a gated switch fires, not every experimental change. Each
/// refresh re-parses the location on screen, which is Experimental features —
/// a page pushed over the shell, whose route match a re-parse swaps for a
/// copy and rebuilds the navigator over, for nothing.
///
/// `DeviceSensors` is not watched. Its answer only ever goes from unknown to
/// present, which opens the gate, and opening needs no re-check: no page
/// could be open that the new answer would close.
final class RouteGateRefresh extends ChangeNotifier {
  ExperimentalSettings? _settings;
  bool _seismometer = false;

  /// Follows [settings] from now on, in place of anything followed before.
  void watch(ExperimentalSettings settings) {
    _settings?.removeListener(_onChanged);
    _settings = settings..addListener(_onChanged);
    _seismometer = settings.seismometerEnabled;
  }

  void _onChanged() {
    final seismometer = _settings?.seismometerEnabled ?? false;
    if (seismometer == _seismometer) return;
    _seismometer = seismometer;
    notifyListeners();
  }
}
