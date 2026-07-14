import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/router/notification_routes.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/realtime/realtime_lifecycle.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
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
        deviceLocationReporter: deps.deviceLocationReporter,
        backgroundLocation: deps.backgroundLocation,
        locationMonitor: deps.locationMonitor,
        onboarding: deps.onboarding,
        // Rebuild MaterialApp when the language override changes (null = system).
        child: Consumer<LocaleController>(
          builder: (context, localeController, _) => MaterialApp.router(
            title: 'DPIP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter,
          ),
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
    required this.deviceLocationReporter,
    required this.backgroundLocation,
    required this.locationMonitor,
    required this.onboarding,
    required this.child,
  });

  final RealtimeService realtimeService;
  final NotificationService notificationService;
  final LocationService locationService;
  final RegionStore regionStore;
  final DeviceLocationReporter deviceLocationReporter;
  final BackgroundLocationService backgroundLocation;
  final LocationMonitor locationMonitor;
  final OnboardingStore onboarding;
  final Widget child;

  @override
  State<_AppServicesHost> createState() => _AppServicesHostState();
}

class _AppServicesHostState extends State<_AppServicesHost>
    with WidgetsBindingObserver {
  late final RealtimeLifecycleObserver _observer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _observer = RealtimeLifecycleObserver(widget.realtimeService);
    WidgetsBinding.instance.addObserver(this);
    NotificationTaps.onTap = _routeNotificationTap;
    widget.onboarding.addListener(_onOnboardingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.realtimeService.startAll();
      NotificationTaps.drainPending();
      // Permissions belong to onboarding — only run the permission-dependent
      // setup once it's complete (immediately for returning users).
      if (widget.onboarding.isComplete) _onReady();
    });
  }

  void _onOnboardingChanged() {
    if (widget.onboarding.isComplete) _onReady();
  }

  /// Runs the permission-*dependent* app setup once, after onboarding (which
  /// owns the permission *requests*). Starts the location monitor and, only if
  /// permission is already granted, resolves + arms reporting — cold launch must
  /// not re-request (a denied user can't be re-prompted and it gives false
  /// confidence; the monitor's banner is the recovery path).
  void _onReady() {
    if (_ready) return;
    _ready = true;
    widget.locationMonitor.start();
    _startLocationIfGranted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-arm background reporting on resume: the Android geofence can be dropped
    // by a Play-services update / location toggle (neither fires boot), so a
    // warm foreground is the reliable re-arm point. (The monitor handles the
    // foreground reporter + town on resume.)
    if (state == AppLifecycleState.resumed && _ready) _armBackground();
  }

  /// Resolves the current township and starts reporting — but only when
  /// foreground location is already granted. Never requests (see [_onReady]).
  Future<void> _startLocationIfGranted() async {
    if (!await widget.locationService.granted()) return;
    final town = await widget.locationService.currentTown();
    if (!mounted) return;
    widget.regionStore.setCurrentCode(town?.code);
    widget.deviceLocationReporter.start();
    await _armBackground();
  }

  /// Arms native background reporting when a push token exists and background
  /// ("Always") location is actually granted — on both platforms (iOS delivers
  /// zero SLC/region events without Always, so assuming it is armed is wrong).
  /// Idempotent; safe to call on every resume.
  Future<void> _armBackground() async {
    final token = widget.notificationService.token;
    if (token == null) return;
    if (!await widget.locationService.backgroundGranted()) return;
    if (!mounted) return;
    widget.backgroundLocation.start(token);
  }

  @override
  void dispose() {
    NotificationTaps.onTap = null;
    widget.onboarding.removeListener(_onOnboardingChanged);
    WidgetsBinding.instance.removeObserver(this);
    _observer.dispose();
    widget.locationMonitor.dispose();
    widget.deviceLocationReporter.dispose();
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
