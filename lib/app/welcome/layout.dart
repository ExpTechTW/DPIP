/// The shared scaffold layout used across all welcome flow pages.
library;

import 'package:flutter/material.dart';

/// Wraps a [child] widget in a [Scaffold] for the welcome onboarding flow.
///
/// Use this as the root widget for each welcome step to get a consistent
/// page chrome without extra configuration.
class WelcomeLayout extends StatelessWidget {
  /// The content to display inside the scaffold body.
  final Widget child;

  /// Creates a [WelcomeLayout] wrapping the given [child].
  const WelcomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
