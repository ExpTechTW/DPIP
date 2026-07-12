import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/realtime_lifecycle.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/radar_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: regions),
        ChangeNotifierProvider.value(value: experimental),
        ChangeNotifierProvider(create: (_) => HomeResetSignal()),
        Provider.value(value: redundantApi),
        Provider.value(value: exclusiveApi),
        Provider.value(value: externalApi),
        Provider<RadarRepository>.value(value: radarRepository),
        Provider<EewRepository>.value(value: eewRepository),
        Provider<RealtimeService>.value(value: realtimeService),
        ChangeNotifierProvider<EewRealtimeController>.value(
          value: eewController,
        ),
      ],
      child: _RealtimeHost(
        service: realtimeService,
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

/// Owns the app-lifecycle wiring for the realtime spine: starts polling after
/// the first frame, pauses/resumes it with the app lifecycle (via
/// [RealtimeLifecycleObserver]), and disposes both on teardown. Separated into a
/// [StatefulWidget] because [AppLifecycleListener] must be created and disposed
/// from a [State].
class _RealtimeHost extends StatefulWidget {
  const _RealtimeHost({required this.service, required this.child});

  final RealtimeService service;
  final Widget child;

  @override
  State<_RealtimeHost> createState() => _RealtimeHostState();
}

class _RealtimeHostState extends State<_RealtimeHost> {
  late final RealtimeLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = RealtimeLifecycleObserver(widget.service);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.startAll();
    });
  }

  @override
  void dispose() {
    _observer.dispose();
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
