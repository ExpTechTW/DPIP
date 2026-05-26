/// Weather condition icon and label for the home page.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// Displays the current weather condition as an icon and description label.
///
/// Shows a generic offline icon when weather data is unavailable. Rebuilds only
/// when the weather description or code changes.
class Weather extends StatelessWidget {
  /// Creates a [Weather] widget.
  const Weather({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, (String, int)?>(
      selector: (_, m) {
        final d = m.weather?.data;
        return d != null ? (d.weather, d.weatherCode) : null;
      },
      builder: (context, data, _) {
        final icon = data != null ? _weatherIcon(data.$2) : Symbols.cloud_off_rounded;
        final color = data != null ? _weatherIconColor(data.$2) : Colors.grey;
        final label = data?.$1 ?? '--';

        return Padding(
          padding: const .symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              Icon(icon, fill: 1, color: color),
              BodyText.large(
                label,
                fontSize: 20,
                color: context.colors.onSurface,
              ),
            ],
          ),
        );
      },
    );
  }
}

IconData _weatherIcon(int code) => switch (code) {
  >= 1 && <= 3 => Symbols.clear_day_rounded,
  >= 4 && <= 7 => Symbols.partly_cloudy_day_rounded,
  >= 8 && <= 14 => Symbols.cloud_rounded,
  >= 15 && <= 22 => Symbols.rainy_rounded,
  >= 23 && <= 28 => Symbols.rainy_heavy_rounded,
  >= 29 && <= 35 => Symbols.thunderstorm_rounded,
  >= 36 && <= 41 => Symbols.weather_snowy_rounded,
  _ => Symbols.foggy_rounded,
};

Color _weatherIconColor(int code) => switch (code) {
  >= 1 && <= 3 => Colors.orangeAccent,
  >= 4 && <= 7 => Colors.amber,
  >= 8 && <= 14 => Colors.grey,
  >= 15 && <= 28 => Colors.blueAccent,
  >= 29 && <= 35 => Colors.yellowAccent,
  >= 36 && <= 41 => Colors.lightBlue,
  _ => Colors.grey,
};
