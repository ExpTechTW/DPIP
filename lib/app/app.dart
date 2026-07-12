import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/core/settings/home_sheet_extent.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/realtime/realtime_lifecycle.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The root widget of the application.
///
/// Provides app-wide services (region selection + API clients) and wires
/// routing and theming.
class DpipApp extends StatelessWidget {
  const DpipApp({
    super.key,
    required this.regions,
    required this.experimental,
    required this.redundantApi,
    required this.exclusiveApi,
    required this.externalApi,
    required this.radarRepository,
    required this.eewRepository,
    required this.realtimeService,
    required this.eewController,
    required this.notificationService,
  });

  /// Region selection state (also the endpoint-selection "state management").
  final RegionSelection regions;

  /// Experimental feature settings (e.g. the home weather-animation override).
  final ExperimentalSettings experimental;

  /// Multi-active (redundant) API surface.
  final RedundantApi redundantApi;

  /// Non-redundant (core-tnn1) API surface.
  final ExclusiveApi exclusiveApi;

  /// Third-party (GitHub/Crowdin/status) API surface.
  final ExternalApi externalApi;

  /// Radar echo frames (map overlay + home backdrop) — repository seam.
  final RadarRepository radarRepository;

  /// Earthquake Early Warning data (repository seam — presentation depends on
  /// this abstraction, not the API).
  final EewRepository eewRepository;

  /// Realtime spine (server clock + polling channels + lifecycle fan-out).
  final RealtimeService realtimeService;

  /// Live EEW feed exposed to the UI as a [ChangeNotifier].
  final EewRealtimeController eewController;

  /// Push-notification setup (channels + FCM/APNs transport + tap routing).
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: regions),
        ChangeNotifierProvider.value(value: experimental),
        ChangeNotifierProvider(create: (_) => AreaSelection()),
        ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
        ChangeNotifierProvider(create: (_) => HomeResetSignal()),
        Provider.value(value: redundantApi),
        Provider.value(value: exclusiveApi),
        Provider.value(value: externalApi),
        Provider<RadarRepository>.value(value: radarRepository),
        Provider<EewRepository>.value(value: eewRepository),
        Provider<RealtimeService>.value(value: realtimeService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<EewRealtimeController>.value(
          value: eewController,
        ),
      ],
      child: _AppServicesHost(
        realtimeService: realtimeService,
        notificationService: notificationService,
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
/// - requesting notification permission once, after the first frame.
class _AppServicesHost extends StatefulWidget {
  const _AppServicesHost({
    required this.realtimeService,
    required this.notificationService,
    required this.child,
  });

  final RealtimeService realtimeService;
  final NotificationService notificationService;
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
    });
  }

  @override
  void dispose() {
    NotificationTaps.onTap = null;
    _observer.dispose();
    widget.realtimeService.dispose();
    super.dispose();
  }

  /// Sends a tapped notification to a tab by its channel key: EEW/earthquake to
  /// the monitor, reports to the map, everything else home.
  void _routeNotificationTap(String channelKey) {
    final route = switch (channelKey) {
      _ when channelKey.startsWith('eew') => AppRoutes.earthquake,
      _ when channelKey.startsWith('eq') => AppRoutes.earthquake,
      _ when channelKey.startsWith('int_report') => AppRoutes.earthquake,
      _ when channelKey.startsWith('report') => AppRoutes.map,
      _ => AppRoutes.home,
    };
    appRouter.goNamed(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
