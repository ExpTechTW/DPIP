/// Detailed weather header widget showing temperature, conditions, and
/// station metadata.
library;

import 'dart:math';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/weather_icon.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Renders a full weather summary for the given [weather] observation,
/// including temperature, feels-like, condition chips, and station info.
///
/// Call [WeatherHeader.skeleton] to show a loading placeholder while data
/// is being fetched.
class WeatherHeader extends StatelessWidget {
  /// The current realtime weather observation to display.
  final RealtimeWeather weather;

  /// Creates a [WeatherHeader] for the given [weather].
  const WeatherHeader(this.weather, {super.key});

  /// Returns a skeleton placeholder that mirrors the layout of [WeatherHeader].
  static Widget skeleton(BuildContext context) {
    return Skeletonizer.zone(
      child: Center(
        child: Column(
          spacing: 12,
          children: [
            Row(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                const Bone.icon(size: 32),
                Bone.text(
                  words: 1,
                  style: context.texts.titleLarge,
                ),
              ],
            ),
            Bone.text(
              width: 140,
              style: context.texts.displayLarge,
            ),
            Row(
              mainAxisSize: .min,
              spacing: 12,
              children: [
                Bone.text(
                  width: 60,
                  style: context.texts.bodyLarge,
                ),
                Bone.text(
                  width: 60,
                  style: context.texts.bodyLarge,
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: .center,
              children: List.generate(
                9,
                (_) => Bone.text(
                  width: 50,
                  style: context.texts.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e =
        weather.data.humidity /
        100 *
        6.105 *
        exp(
          17.27 * weather.data.temperature / (weather.data.temperature + 237.3),
        );
    final feelsLike = weather.data.temperature + 0.33 * e - 0.7 * weather.data.wind.speed - 4.0;

    return ResponsiveContainer(
      child: Padding(
        padding: const .symmetric(horizontal: 12),
        child: Column(
          spacing: 12,
          children: [
            Row(
              mainAxisSize: .min,
              spacing: 6,
              children: [
                Container(
                  padding: const .all(8),
                  decoration: BoxDecoration(
                    color: context.colors.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: .circular(12),
                  ),
                  child: Icon(
                    WeatherIcons.getWeatherIcon(
                      weather.data.weatherCode,
                      true,
                    ),
                    size: 32,
                    color: context.colors.secondary,
                  ),
                ),
                Text(
                  WeatherIcons.getWeatherContent(
                    context,
                    weather.data.weatherCode,
                  ),
                  style: context.texts.titleLarge!.copyWith(
                    color: context.colors.secondary,
                    fontWeight: .bold,
                  ),
                ),
              ],
            ),
            Selector<SettingsUserInterfaceModel, bool>(
              selector: (context, model) => model.useFahrenheit,
              builder: (context, useFahrenheit, child) {
                final value = weather.data.temperature;
                final displayTemp = (useFahrenheit ? value.asFahrenheit : value).round();
                final displayFeelsLike = (useFahrenheit ? feelsLike.asFahrenheit : feelsLike)
                    .round();

                return Column(
                  spacing: 8,
                  children: [
                    Text(
                      '$displayTemp°',
                      style: context.texts.displayLarge!.copyWith(
                        fontSize: 64,
                        color: context.colors.onSurface,
                        fontWeight: .w200,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    Container(
                      padding: const .symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: .circular(20),
                      ),
                      child: Text(
                        '體感 $displayFeelsLike°'.i18n,
                        style: context.texts.bodyLarge!.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: .w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: .center,
              children: [
                _buildInfoChip(
                  context,
                  Symbols.water_drop_rounded,
                  '濕度'.i18n,
                  '${weather.data.humidity >= 0 ? weather.data.humidity.round() : "-"}%',
                  Colors.blue,
                ),
                _buildInfoChip(
                  context,
                  Symbols.wind_power_rounded,
                  '風速'.i18n,
                  weather.data.wind.speed >= 0 ? '${weather.data.wind.speed}m/s' : '-',
                  Colors.teal,
                ),
                _buildInfoChip(
                  context,
                  Symbols.explore_rounded,
                  '風向'.i18n,
                  weather.data.wind.direction.isNotEmpty ? weather.data.wind.direction : '-',
                  Colors.cyan,
                ),
                _buildInfoChip(
                  context,
                  Symbols.wind_power_rounded,
                  '風級'.i18n,
                  weather.data.wind.beaufort > 0 ? '${weather.data.wind.beaufort}級'.i18n : '-',
                  Colors.teal,
                ),
                _buildInfoChip(
                  context,
                  Symbols.compress_rounded,
                  '氣壓'.i18n,
                  weather.data.pressure >= 0 ? '${weather.data.pressure.round()}hPa' : '-',
                  Colors.orange,
                ),
                _buildInfoChip(
                  context,
                  Symbols.rainy_rounded,
                  '降雨'.i18n,
                  weather.data.rain >= 0 ? '${weather.data.rain}mm' : '-',
                  Colors.indigo,
                ),
                _buildInfoChip(
                  context,
                  Symbols.visibility_rounded,
                  '能見度'.i18n,
                  weather.data.visibility >= 0 ? '${weather.data.visibility.round()}km' : '-',
                  Colors.grey,
                ),
                if (weather.data.gust.speed > 0)
                  _buildInfoChip(
                    context,
                    Symbols.air_rounded,
                    '陣風'.i18n,
                    '${weather.data.gust.speed}m/s',
                    Colors.purple,
                  ),
                if (weather.data.gust.beaufort > 0)
                  _buildInfoChip(
                    context,
                    Symbols.wind_power_rounded,
                    '陣風級'.i18n,
                    '${weather.data.gust.beaufort}級'.i18n,
                    Colors.deepPurple,
                  ),
                if (weather.data.sunshine >= 0)
                  _buildInfoChip(
                    context,
                    Symbols.wb_sunny_rounded,
                    '日照'.i18n,
                    '${weather.data.sunshine.toStringAsFixed(1)}h',
                    Colors.amber,
                  ),
              ],
            ),
            Container(
              margin: const .only(top: 4),
              padding: const .symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: .circular(16),
              ),
              child: Row(
                mainAxisSize: .min,
                spacing: 6,
                children: [
                  Icon(
                    Symbols.pin_drop_rounded,
                    size: 14,
                    color: context.colors.onSurfaceVariant,
                  ),
                  Text(
                    '${weather.station.name}氣象站'.i18n,
                    style: context.texts.bodySmall!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    margin: const .symmetric(horizontal: 4),
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  Text(
                    '${weather.station.distance.toStringAsFixed(1)}km',
                    style: context.texts.bodySmall!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    margin: const .symmetric(horizontal: 4),
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  Icon(
                    Symbols.schedule_rounded,
                    size: 14,
                    color: context.colors.onSurfaceVariant,
                  ),
                  Text(
                    weather.time.toLocaleTimeString(context).substring(0, 5),
                    style: context.texts.bodySmall!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String text,
    Color color,
  ) {
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: .circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: 5,
        children: [
          Icon(icon, size: 14, color: color, weight: 600),
          Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(
                label,
                style: context.texts.bodySmall!.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 9,
                  height: 1.0,
                ),
              ),
              Text(
                text,
                style: context.texts.bodySmall!.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: .w600,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
