/// Large temperature display for the home page.
library;

import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Displays the current temperature in a large, thin-weight format.
///
/// Shows "--" when weather data is unavailable. Rebuilds only when the
/// temperature value changes.
class Temperature extends StatelessWidget {
  /// Creates a [Temperature] widget.
  const Temperature({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, double?>(
      selector: (_, m) => m.weather?.data.temperature,
      builder: (context, temp, _) {
        final tempStr = temp != null ? temp.toStringAsFixed(1) : '--';
        return Padding(
          padding: const .symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: .start,
            crossAxisAlignment: .start,
            children: [
              DisplayText.large(
                tempStr,
                color: context.colors.secondaryFixed,
                fontFamily: 'Google Sans Flex',
                fontSize: 96,
                fontVariations: [const .new('ROND', 100)],
                shadows: kElevationToShadow[4],
              ),
              DisplayText.large(
                '°',
                color: context.colors.secondaryFixed,
                fontFamily: 'Google Sans Flex',
                weight: .w300,
                fontSize: 96,
                fontVariations: [const .new('ROND', 100)],
                shadows: kElevationToShadow[4],
              ),
            ],
          ),
        );
      },
    );
  }
}
