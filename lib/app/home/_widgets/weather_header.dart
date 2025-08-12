import 'dart:math';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/double.dart';
import 'package:dpip/utils/weather_icon.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WeatherHeader extends StatelessWidget {
  final RealtimeWeather weather;

  const WeatherHeader(this.weather, {super.key});

  static Widget skeleton(BuildContext context) {
    final separator = Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: context.colors.onSurfaceVariant, shape: BoxShape.circle),
    );

    return Skeletonizer.zone(
      child: Center(
        child: Column(
          spacing: 32,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [const Bone.icon(size: 28), Bone.text(words: 1, style: context.theme.textTheme.titleLarge)],
            ),
            Bone.text(width: 128, style: context.theme.textTheme.displayLarge),
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Bone.text(words: 1, style: context.theme.textTheme.bodyLarge),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    const Bone.icon(size: 16),
                    Bone.text(width: 32, style: context.theme.textTheme.bodyLarge),
                    separator,
                    const Bone.icon(size: 16),
                    Bone.text(width: 32, style: context.theme.textTheme.bodyLarge),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    const Bone.icon(size: 16),
                    Bone.text(width: 48, style: context.theme.textTheme.bodyLarge),
                    separator,
                    const Bone.icon(size: 16),
                    Bone.text(width: 72, style: context.theme.textTheme.bodyLarge),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [const Bone.icon(size: 16), Bone.text(words: 1, style: context.theme.textTheme.bodyLarge)],
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
    // Apparent temperature formula from https://en.wikipedia.org/wiki/Apparent_temperature
    final e =
        weather.weather.data.air.relativeHumidity /
        100 *
        6.105 *
        exp(17.27 * weather.weather.data.air.temperature / (weather.weather.data.air.temperature + 237.3));
    final feelsLike = weather.weather.data.air.temperature + 0.33 * e - 0.7 * weather.weather.data.wind.speed - 4.0;

    return Center(
      child: Column(
        spacing: 24,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(
                WeatherIcons.getWeatherIcon(weather.weather.data.weatherCode, true),
                size: 28,
                color: context.colors.secondary,
              ),
              Text(
                WeatherIcons.getWeatherContent(context, weather.weather.data.weatherCode),
                style: context.theme.textTheme.titleLarge!.copyWith(color: context.colors.secondary),
              ),
            ],
          ),
          Selector<SettingsUserInterfaceModel, bool>(
            selector: (context, model) => model.useFahrenheit,
            builder: (context, useFahrenheit, child) {
              final value = weather.weather.data.air.temperature;
              return Text(
                // keeping a space at start to make the temperature look more center visually
                ' ${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                style: context.theme.textTheme.displayLarge!.copyWith(fontSize: 64, color: context.colors.onSurface),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Selector<SettingsUserInterfaceModel, bool>(
                selector: (context, model) => model.useFahrenheit,
                builder: (context, useFahrenheit, child) {
                  return Text(
                    '體感約 {apparent}°'.i18n.args({
                      'apparent': (useFahrenheit ? feelsLike.asFahrenheit : feelsLike).round(),
                    }),
                    style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                  );
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(Symbols.thermostat_arrow_up_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  Selector<SettingsUserInterfaceModel, bool>(
                    selector: (context, model) => model.useFahrenheit,
                    builder: (context, useFahrenheit, child) {
                      final value = weather.weather.daily.high.temperature;
                      return Text(
                        '${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                        style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                      );
                    },
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.colors.onSurfaceVariant, shape: BoxShape.circle),
                  ),
                  Icon(Symbols.thermostat_arrow_down_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  Selector<SettingsUserInterfaceModel, bool>(
                    selector: (context, model) => model.useFahrenheit,
                    builder: (context, useFahrenheit, child) {
                      final value = weather.weather.daily.low.temperature;
                      return Text(
                        '${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                        style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(Symbols.water_drop_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  Text(
                    '${weather.weather.data.air.relativeHumidity}%',
                    style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.colors.onSurfaceVariant, shape: BoxShape.circle),
                  ),
                  Icon(Symbols.wind_power_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  Text(
                    '${weather.weather.data.wind.speed}m/s',
                    style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(Symbols.pin_drop_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  Text(
                    '${weather.weather.station.name}站'.i18n,
                    style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
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
