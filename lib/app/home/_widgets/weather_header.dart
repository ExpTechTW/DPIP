import 'dart:math';

import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/double.dart';
import 'package:dpip/utils/weather_icon.dart';

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Selector<SettingsLocationModel, String?>(
        selector: (context, model) => model.code,
        builder: (context, code, child) {
          final location = Global.location[code];

          if (code == null || location == null) return child!;

          return FutureBuilder(
            future: (() async => await ExpTech().getWeatherRealtime(code))(),
            builder: (context, snapshot) {
              final data = snapshot.data;

              if (data == null) {
                return const CircularProgressIndicator();
              }

              // Apparent temperature formula from https://en.wikipedia.org/wiki/Apparent_temperature
              final e =
                  data.weather.data.air.relative_humidity /
                  100 *
                  6.105 *
                  exp(17.27 * data.weather.data.air.temperature / (data.weather.data.air.temperature + 237.3));
              final feelsLike = data.weather.data.air.temperature + 0.33 * e - 0.7 * data.weather.data.wind.speed - 4.0;

              return Column(
                spacing: 24,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        WeatherIcons.getWeatherIcon(data.weather.data.weatherCode, true),
                        size: 28,
                        color: context.colors.secondary,
                      ),
                      Text(
                        WeatherIcons.getWeatherContent(context, data.weather.data.weatherCode),
                        style: context.theme.textTheme.titleLarge!.copyWith(color: context.colors.secondary),
                      ),
                    ],
                  ),
                  Selector<SettingsUserInterfaceModel, bool>(
                    selector: (context, model) => model.useFahrenheit,
                    builder: (context, useFahrenheit, child) {
                      final value = data.weather.data.air.temperature;
                      return Text(
                        // keeping a space at start to make the temperature look more center visually
                        ' ${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                        style: context.theme.textTheme.displayLarge!.copyWith(
                          fontSize: 64,
                          color: context.colors.onSurface,
                        ),
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
                            '體感約 ${(useFahrenheit ? feelsLike.asFahrenheit : feelsLike).round()}°',
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
                              final value = data.weather.daily.high.temperature;
                              return Text(
                                '${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                                style: context.theme.textTheme.bodyLarge!.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
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
                              final value = data.weather.daily.low.temperature;
                              return Text(
                                '${(useFahrenheit ? value.asFahrenheit : value).round()}°',
                                style: context.theme.textTheme.bodyLarge!.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
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
                            '${data.weather.data.air.relative_humidity}%',
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
                            '${data.weather.data.wind.speed}m/s',
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
                            data.weather.station.name,
                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
