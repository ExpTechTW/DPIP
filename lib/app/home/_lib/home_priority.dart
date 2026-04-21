library;

import 'package:collection/collection.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/forecast_card.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/weather_details_card.dart';
import 'package:dpip/app/home/_widgets/wind_card.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:flutter/material.dart';

History? pickActiveThunderstorm(List<History>? realtimeRegion) {
  if (realtimeRegion == null) return null;
  return realtimeRegion
      .where((e) => e.type == HistoryType.thunderstorm)
      .sorted((a, b) => b.time.send.compareTo(a.time.send))
      .firstOrNull;
}

/// 排序首頁卡片 優先級: EEW -> 雷 -> 天氣 -> 預報 -> 風
List<Widget> buildHomeFeedModules({
  required List<Eew> eews,
  required History? thunderstorm,
  required RealtimeWeather? weather,
  required Map<String, dynamic>? forecast,
  required List<HomeDisplaySection> sections,
  required bool isOutOfService,
  required bool isLoading,
  required Key radarKey,
}) {
  final modules = <Widget>[];

  for (final eew in eews) {
    modules.add(
      Padding(
        key: ValueKey('eew-${eew.id}-${eew.serial}'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: EewCard(eew),
      ),
    );
  }

  if (thunderstorm != null) {
    modules.add(
      Padding(
        key: ValueKey('thunderstorm-${thunderstorm.id}'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ThunderstormCard(thunderstorm),
      ),
    );
  }

  if (!isOutOfService && !isLoading && weather != null) {
    modules.add(
      WeatherDetailsCard(
        key: const ValueKey('weather-details'),
        weather: weather,
      ),
    );
  }

  for (final section in sections) {
    switch (section) {
      case HomeDisplaySection.radar:
        modules.add(
          Padding(
            key: const ValueKey('section-radar'),
            padding: const EdgeInsets.all(16),
            child: RadarMapCard(key: radarKey),
          ),
        );
      case HomeDisplaySection.forecast:
        if (forecast != null) {
          modules.add(
            KeyedSubtree(
              key: const ValueKey('section-forecast'),
              child: ForecastCard(forecast),
            ),
          );
        }
      case HomeDisplaySection.wind:
        if (weather != null) {
          modules.add(
            KeyedSubtree(
              key: const ValueKey('section-wind'),
              child: WindCard(weather),
            ),
          );
        }
    }
  }

  return modules;
}
