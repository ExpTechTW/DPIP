/// A grid of weather parameter cards for the home page.
library;

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

typedef _Params = ({
  double? humidity,
  RealtimeWeatherWind? wind,
  double? rain,
});

/// A 2×2 grid of cards showing humidity, air quality, wind, and rainfall.
///
/// Reads values from [HomeModel] and rebuilds only when the relevant weather
/// parameters change.
class WeatherParameters extends StatelessWidget {
  /// Creates a [WeatherParameters] widget.
  const WeatherParameters({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, _Params>(
      selector: (_, m) {
        final d = m.weather?.data;
        return (
          humidity: d?.humidity,
          wind: d?.wind,
          rain: d?.rain,
        );
      },
      builder: (context, params, _) {
        final (:humidity, :wind, :rain) = params;

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 7 / 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const .symmetric(horizontal: 12, vertical: 4),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _ParameterCard(
              icon: const Icon(Symbols.water_drop_rounded, fill: 1, color: Colors.blueAccent),
              label: Text('相對溼度'.i18n),
              value: humidity != null ? '${humidity.round()}%' : '--',
            ),
            _ParameterCard(
              icon: const Icon(Symbols.mist_rounded, fill: 1, color: Colors.grey),
              label: Text('空氣品質'.i18n),
              value: '--',
            ),
            _ParameterCard(
              icon: const Icon(Symbols.air_rounded, fill: 1, color: Colors.lightBlue),
              label: Text('風向/風速'.i18n),
              value: wind != null && wind.direction.isNotEmpty ? wind.direction : '--',
              footer: wind != null ? Text('${wind.speed.toStringAsFixed(1)} m/s') : null,
            ),
            _ParameterCard(
              icon: const Icon(Symbols.umbrella_rounded, fill: 1, color: Colors.indigoAccent),
              label: Text('降水量'.i18n),
              value: rain != null ? '${rain.toStringAsFixed(1)} mm' : '--',
            ),
          ],
        );
      },
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final Icon icon;
  final Widget label;
  final String value;
  final Widget? footer;

  const _ParameterCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 4,
          children: [
            Row(
              spacing: 4,
              children: [
                icon,
                DefaultTextStyle(
                  style: context.texts.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  child: label,
                ),
              ],
            ),
            HeadLineText.medium(value, weight: .bold),
            if (footer != null)
              DefaultTextStyle(
                style: context.texts.bodyLarge!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}
