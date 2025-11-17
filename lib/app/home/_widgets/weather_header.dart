import 'dart:math';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/weather_icon.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WeatherHeader extends StatelessWidget {
  final RealtimeWeather weather;

  const WeatherHeader(this.weather, {super.key});

  static Widget skeleton(BuildContext context) {
    final separator = Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: context.colors.onSurfaceVariant, shape: BoxShape.circle),
    );

    return Skeletonizer.zone(
      child: Center(
        child: Column(
          spacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                const Bone.icon(size: 24),
                Bone.text(words: 1, style: context.theme.textTheme.titleMedium),
              ],
            ),
            Bone.text(width: 120, style: context.theme.textTheme.displayLarge),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Bone.text(words: 1, style: context.theme.textTheme.bodyMedium),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    const Bone.icon(size: 14),
                    Bone.text(width: 28, style: context.theme.textTheme.bodySmall),
                    separator,
                    const Bone.icon(size: 14),
                    Bone.text(width: 28, style: context.theme.textTheme.bodySmall),
                    separator,
                    const Bone.icon(size: 14),
                    Bone.text(width: 28, style: context.theme.textTheme.bodySmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    const Bone.icon(size: 14),
                    Bone.text(width: 40, style: context.theme.textTheme.bodySmall),
                    separator,
                    const Bone.icon(size: 14),
                    Bone.text(width: 40, style: context.theme.textTheme.bodySmall),
                    separator,
                    const Bone.icon(size: 14),
                    Bone.text(width: 40, style: context.theme.textTheme.bodySmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    const Bone.icon(size: 14),
                    Bone.text(width: 60, style: context.theme.textTheme.bodySmall),
                  ],
                ),
              ],
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
        exp(17.27 * weather.data.temperature / (weather.data.temperature + 237.3));
    final feelsLike = weather.data.temperature + 0.33 * e - 0.7 * weather.data.wind.speed - 4.0;
    final separator = Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: context.colors.onSurfaceVariant.withValues(alpha: 0.6), shape: BoxShape.circle),
    );

    return Center(
      child: Column(
        spacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Icon(
                WeatherIcons.getWeatherIcon(weather.data.weatherCode, true),
                size: 28,
                color: context.colors.secondary,
              ),
              Text(
                WeatherIcons.getWeatherContent(context, weather.data.weatherCode),
                style: context.theme.textTheme.titleMedium!.copyWith(
                  color: context.colors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Selector<SettingsUserInterfaceModel, bool>(
            selector: (context, model) => model.useFahrenheit,
            builder: (context, useFahrenheit, child) {
              final value = weather.data.temperature;
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    '${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                    style: context.theme.textTheme.displayLarge!.copyWith(
                      fontSize: 52,
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '體感 ${(useFahrenheit ? feelsLike.asFahrenheit : feelsLike).round()}°'.i18n,
                      style: context.theme.textTheme.bodySmall!.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(Symbols.water_drop_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.humidity >= 0 ? '${weather.data.humidity.round()}%' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  separator,
                  Icon(Symbols.wind_power_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.wind.speed >= 0 ? '${weather.data.wind.speed}m/s ${weather.data.wind.direction}' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  separator,
                  Icon(Symbols.compress_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.pressure >= 0 ? '${weather.data.pressure.round()}hPa' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(Symbols.rainy_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.rain >= 0 ? '${weather.data.rain}mm' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  separator,
                  Icon(Symbols.visibility_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.visibility >= 0 ? '${weather.data.visibility.round()}km' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  separator,
                  Icon(Symbols.air_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    weather.data.gust.speed >= 0 ? '${weather.data.gust.speed}m/s' : '-',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(Symbols.pin_drop_rounded, size: 13, color: context.colors.onSurfaceVariant),
                  Text(
                    '${weather.station.name}氣象站',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  separator,
                  Text(
                    '距離 ${weather.station.distance.toStringAsFixed(1)}km',
                    style: context.theme.textTheme.bodySmall!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
