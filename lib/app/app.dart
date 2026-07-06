import 'package:dpip/app/router/app_router.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The root widget of the application.
///
/// Wires routing and theming. Feature-level state is provided closer to where
/// it is consumed rather than globally here.
class DpipApp extends StatelessWidget {
  const DpipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DPIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
