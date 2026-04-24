/// A grid of weather parameter cards for the home page.
library;

import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

typedef _Params = ({double humidity, String windDir, double windSpeed, double rain})?;

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
        if (d == null) return null;
        return (
          humidity: d.humidity,
          windDir: d.wind.direction,
          windSpeed: d.wind.speed,
          rain: d.rain,
        );
      },
      builder: (context, params, _) {
        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 7 / 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: .symmetric(horizontal: 12, vertical: 4),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _ParameterCard(
              icon: const Icon(Symbols.water_drop_rounded, fill: 1, color: Colors.blueAccent),
              label: '相對溼度',
              value: params != null ? '${params.humidity.round()}%' : '--',
            ),
            _ParameterCard(
              icon: Icon(Symbols.mist_rounded, fill: 1, color: Colors.grey),
              label: '空氣品質',
              value: '--',
            ),
            _ParameterCard(
              icon: const Icon(Symbols.air_rounded, fill: 1, color: Colors.lightBlue),
              label: '風向/風速',
              value: params != null && params.windDir.isNotEmpty ? params.windDir : '--',
              footer: params != null ? '${params.windSpeed.toStringAsFixed(1)} m/s' : null,
            ),
            _ParameterCard(
              icon: const Icon(Symbols.umbrella_rounded, fill: 1, color: Colors.indigoAccent),
              label: '降水量',
              value: params != null ? '${params.rain.toStringAsFixed(1)} mm' : '--',
            ),
          ],
        );
      },
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final Icon icon;
  final String label;
  final String value;
  final String? footer;
  final Color? footerColor;

  const _ParameterCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footer,
    this.footerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: .all(16),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 4,
          children: [
            Row(
              spacing: 4,
              children: [
                icon,
                BodyText.medium(label, color: context.colors.onSurfaceVariant),
              ],
            ),
            HeadLineText.medium(value, weight: .bold),
            if (footer != null)
              BodyText.large(footer!, color: footerColor ?? context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
