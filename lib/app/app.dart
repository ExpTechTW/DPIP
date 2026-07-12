import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/map/data/radar_api.dart';
import 'package:dpip/features/settings/presentation/experimental_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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
    required this.radarApi,
    required this.eewRepository,
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

  /// Radar echo tile endpoints (map overlay).
  final RadarApi radarApi;

  /// Earthquake Early Warning data (repository seam — presentation depends on
  /// this abstraction, not the API).
  final EewRepository eewRepository;

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
        Provider.value(value: radarApi),
        Provider<EewRepository>.value(value: eewRepository),
      ],
      child: MaterialApp.router(
        title: 'DPIP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
