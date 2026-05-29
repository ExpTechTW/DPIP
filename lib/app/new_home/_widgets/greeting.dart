/// A greeting widget that displays a time-aware salutation.
library;

import 'package:dpip/app/new_home/_models/weather_params.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';

/// Displays a greeting that changes based on the current hour.
class Greeting extends StatelessWidget {
  /// Creates a [Greeting] widget.
  const Greeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(16),
      child: TitleText.large(
        greetingForHour(DateTime.now().hour).i18n,
        color: Colors.white,
        shadows: kElevationToShadow[2],
      ),
    );
  }
}
