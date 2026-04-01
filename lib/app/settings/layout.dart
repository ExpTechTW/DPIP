/// Shared scaffold layout for all settings pages.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A scaffold wrapper for settings pages.
///
/// Provides a consistent app bar with a back button and applies the
/// fade-forward page transition theme to its [child]:
///
/// ```dart
/// SettingsLayout(
///   child: MySettingsPage(),
/// )
/// ```
class SettingsLayout extends StatefulWidget {
  /// The settings page content to display inside the scaffold body.
  final Widget child;

  /// Creates a [SettingsLayout].
  const SettingsLayout({super.key, required this.child});

  @override
  State<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<SettingsLayout> {
  final controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: context.theme.copyWith(
        pageTransitionsTheme: kFadeForwardPageTransitionsTheme,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('設定'.i18n),
          leading: BackButton(onPressed: () => context.pop()),
          centerTitle: true,
        ),
        body: widget.child,
      ),
    );
  }
}
