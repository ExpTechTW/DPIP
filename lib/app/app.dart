import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/router/notification_routes.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/realtime/realtime_lifecycle.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The root widget of the application.
///
/// Installs the aggregated [providers] (assembled per-feature in `bootstrap`)
/// and wires routing, theming, and the app-level service lifecycle. It stays
/// feature-agnostic: adding a feature adds providers to the list, never a field
/// here.
class DpipApp extends StatelessWidget {
  const DpipApp({super.key, required this.deps, required this.providers});

  /// Shared infrastructure the service host needs (realtime + notifications).
  final SharedDeps deps;

  /// Every feature's providers, aggregated in `bootstrap`.
  final List<SingleChildWidget> providers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: _AppServicesHost(
        realtimeService: deps.realtimeService,
        notificationService: deps.notificationService,
        locationService: deps.locationService,
        regionStore: deps.regionStore,
        child: MaterialApp.router(
          title: 'DPIP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}

/// Owns app-level service wiring that needs a [State]/lifecycle:
/// - the realtime spine's start/pause/resume (via [RealtimeLifecycleObserver]);
/// - routing a tapped notification to the right tab (the channel-key → route
///   mapping lives here because this layer owns the router);
/// - requesting notification permission once, after the first frame;
/// - resolving the current GPS township into the [RegionStore] so 所在地 shows
///   the real location (and the "can't get location" state when GPS is off).
class _AppServicesHost extends StatefulWidget {
  const _AppServicesHost({
    required this.realtimeService,
    required this.notificationService,
    required this.locationService,
    required this.regionStore,
    required this.child,
  });

  final RealtimeService realtimeService;
  final NotificationService notificationService;
  final LocationService locationService;
  final RegionStore regionStore;
  final Widget child;

  @override
  State<_AppServicesHost> createState() => _AppServicesHostState();
}

class _AppServicesHostState extends State<_AppServicesHost> {
  late final RealtimeLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = RealtimeLifecycleObserver(widget.realtimeService);
    NotificationTaps.onTap = _routeNotificationTap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.realtimeService.startAll();
      NotificationTaps.drainPending();
      widget.notificationService.requestPermission();
      _resolveCurrentLocation();
    });
  }

  /// Requests GPS permission and resolves the current township into the region
  /// store. On denial/error the current code stays null, so 所在地 renders its
  /// "can't get current location" state rather than a wrong region.
  Future<void> _resolveCurrentLocation() async {
    await widget.locationService.requestPermission();
    final town = await widget.locationService.currentTown();
    if (!mounted) return;
    widget.regionStore.setCurrentCode(town?.code);
  }

  @override
  void dispose() {
    NotificationTaps.onTap = null;
    _observer.dispose();
    widget.realtimeService.dispose();
    super.dispose();
  }

  /// Sends a tapped notification to a screen. The destination is resolved by the
  /// declarative channel→route table; the tap's [NotificationTap.id] is carried
  /// for the per-item detail routes to come.
  void _routeNotificationTap(NotificationTap tap) {
    appRouter.goNamed(routeForNotificationChannel(tap.channelKey));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
