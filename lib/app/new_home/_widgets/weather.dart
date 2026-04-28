/// Weather condition icon and label for the home page.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
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
              Icon(
                icon,
                fill: 1,
                color: color,
                shadows: kElevationToShadow[2],
              ),
              BodyText.large(
                label,
                fontSize: 20,
                color: Colors.white,
                shadows: kElevationToShadow[2],
              ),
            ],
          ),
        );
      },
    );
  }
}

IconData _weatherIcon(int code) {
  if (code >= 1 && code <= 3) return Symbols.clear_day_rounded;
  if (code >= 4 && code <= 7) return Symbols.partly_cloudy_day_rounded;
  if (code >= 8 && code <= 14) return Symbols.cloud_rounded;
  if (code >= 15 && code <= 22) return Symbols.rainy_rounded;
  if (code >= 23 && code <= 28) return Symbols.rainy_heavy_rounded;
  if (code >= 29 && code <= 35) return Symbols.thunderstorm_rounded;
  if (code >= 36 && code <= 41) return Symbols.weather_snowy_rounded;
  return Symbols.foggy_rounded;
}

Color _weatherIconColor(int code) {
  if (code >= 1 && code <= 3) return Colors.orangeAccent;
  if (code >= 4 && code <= 7) return Colors.amber;
  if (code >= 8 && code <= 14) return Colors.grey;
  if (code >= 15 && code <= 28) return Colors.blueAccent;
  if (code >= 29 && code <= 35) return Colors.yellowAccent;
  if (code >= 36 && code <= 41) return Colors.lightBlue;
  return Colors.grey;
}
