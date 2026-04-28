/// A greeting widget that displays a time-aware salutation.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';

/// Displays a greeting that changes based on the current hour.
class Greeting extends StatelessWidget {
  /// Creates a [Greeting] widget.
  const Greeting({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      < 6 => '夜深了',
      < 12 => '早安',
      < 18 => '午安',
      _ => '晚安',
    };

    return Padding(
      padding: const .all(16),
      child: TitleText.large(
        greeting.i18n,
        color: Colors.white,
        shadows: kElevationToShadow[2],
      ),
    );
  }
}
