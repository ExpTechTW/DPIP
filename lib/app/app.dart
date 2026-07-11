import 'package:dpip/api/exclusive_api.dart';
import 'package:dpip/api/external_api.dart';
import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/network/region_selection.dart';
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
    required this.redundantApi,
    required this.exclusiveApi,
    required this.externalApi,
  });

  /// Region selection state (also the endpoint-selection "state management").
  final RegionSelection regions;

  /// Multi-active (redundant) API surface.
  final RedundantApi redundantApi;

  /// Non-redundant (core-tnn1) API surface.
  final ExclusiveApi exclusiveApi;

  /// Third-party (GitHub/Crowdin/status) API surface.
  final ExternalApi externalApi;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: regions),
        Provider.value(value: redundantApi),
        Provider.value(value: exclusiveApi),
        Provider.value(value: externalApi),
      ],
      child: MaterialApp.router(
        title: 'DPIP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
