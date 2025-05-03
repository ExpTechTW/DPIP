import 'dart:math';

import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app_old/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app_old/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/double.dart';
import 'package:dpip/utils/time_convert.dart';
import 'package:dpip/utils/weather_icon.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
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
                            exp(
                              17.27 * data.weather.data.air.temperature / (data.weather.data.air.temperature + 237.3),
                            );
                        final feelsLike =
                            data.weather.data.air.temperature + 0.33 * e - 0.7 * data.weather.data.wind.speed - 4.0;

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
                                      style: context.theme.textTheme.bodyLarge!.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Icon(
                                      Symbols.thermostat_arrow_up_rounded,
                                      size: 16,
                                      color: context.colors.onSurfaceVariant,
                                    ),
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
                                      decoration: BoxDecoration(
                                        color: context.colors.onSurfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Icon(
                                      Symbols.thermostat_arrow_down_rounded,
                                      size: 16,
                                      color: context.colors.onSurfaceVariant,
                                    ),
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
                                      style: context.theme.textTheme.bodyLarge!.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: context.colors.onSurfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Icon(Symbols.wind_power_rounded, size: 16, color: context.colors.onSurfaceVariant),
                                    Text(
                                      '${data.weather.data.wind.speed}m/s',
                                      style: context.theme.textTheme.bodyLarge!.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
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
                                      style: context.theme.textTheme.bodyLarge!.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
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
              ),
            ),

            Padding(padding: const EdgeInsets.all(16), child: EewCard()),
            Padding(padding: const EdgeInsets.all(16), child: RadarMapCard()),

            Selector<SettingsLocationModel, String?>(
              selector: (context, model) => model.code,
              builder: (context, code, child) {
                final location = Global.location[code];

                if (code == null || location == null) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder(
                  future: ExpTech().getHistoryRegion(code),
                  builder: (context, snapshot) {
                    final data = snapshot.data;

                    if (data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (data.isEmpty) {
                      return Center(child: Text(context.i18n.home_safety));
                    }

                    final grouped = groupBy(
                      data,
                      (e) =>
                          DateFormat(context.i18n.full_date_format, context.locale.toLanguageTag()).format(e.time.send),
                    );

                    return Column(
                      children:
                          grouped.entries.mapIndexed((index, entry) {
                            final date = entry.key;
                            final historyGroup = entry.value;
                            return Column(
                              children: [
                                DateTimelineItem(date, first: index == 0),
                                ...historyGroup.map((history) {
                                  final int? expireTimestamp = history.time.expires['all'];
                                  final TZDateTime expireTimeUTC = convertToTZDateTime(expireTimestamp ?? 0);
                                  final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
                                  return HistoryTimelineItem(
                                    expired: isExpired,
                                    history: history,
                                    last: history == data.last,
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
        Positioned(top: 48, left: 0, right: 0, child: Align(alignment: Alignment.topCenter, child: LocationButton())),
      ],
    );
  }
}
