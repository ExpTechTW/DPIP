import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/core/weather/weather_icons.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/solar_time.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The header at the top of the home sheet: the selected area name and, for a
/// township, its current weather — condition icon + temperature on the left
/// (2/3), precipitation over humidity on the right (1/3). The nearest-station
/// name + observation time (Taipei HH:mm) sit as small print under the name,
/// with a "view on map" link that opens the map on that station's temperature
/// layer. 全國 shows the name only (no point weather).
///
/// Readings are shown only while they belong to the *selected* area — a
/// previous area's observation is held by the controller while the new fetch
/// runs, but a wrong-area temperature must never masquerade as the new one
/// (the sheet shows dashes instead until the new reading lands).
///
/// When [expanded] (sheet flush full-screen), typography and layout step up to
/// fill the hero band — same pattern as the station/typhoon chart sheets — so a
/// full-height sheet doesn't look like a short card on a void. Weather follows
/// the selected area via [HomeWeatherController]; a dash shows while the first
/// fetch is in flight. Ink tracks the weather sky via [inkOverWeather] — dark
/// theme [ColorScheme.onSurface] is white and vanishes on a clear daylight
/// backdrop without that shift.
class HomeSheetHeader extends StatelessWidget {
  const HomeSheetHeader({
    super.key,
    this.reveal = 0,
    this.expanded = false,
    this.weatherMode = WeatherMode.auto,
    this.sky,
  });

  /// Weather-backdrop reveal (0→1) — drives sky-aware ink.
  final double reveal;

  /// Sheet is at (or past) the full-screen detent — drive larger type + layout.
  final bool expanded;

  /// Which sky the backdrop is rendering — the fallback [skyIsLightFrom] uses
  /// before [sky] exists.
  final WeatherMode weatherMode;

  /// The sky colour the header sits on — `SkyLutCache.panelAmbient`, or null
  /// before the first bake. The header sits directly on the raw sky with no
  /// card behind it, so this is the one place a wrong light/dark call is most
  /// visible: a clear night sky and a clear noon sky are the same [weatherMode]
  /// but opposite ends of the ink decision.
  final Color? sky;

  static final DateFormat _clockFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final skyIsLight = skyIsLightFrom(sky, weatherMode);
    // Directly on the weather sky — not inside a glass card. Dark theme's
    // onSurface is white; on clear/fog daylight that must go dark with reveal.
    final foreground = inkOverWeather(colors, reveal, skyIsLight: skyIsLight);
    final secondary = inkOverWeatherVariant(
      colors,
      reveal,
      skyIsLight: skyIsLight,
    );

    final directory = context.read<TownDirectory>();
    final area = context.select<RegionStore, HomeArea>(
      (store) => store.selected,
    );
    final areaName = switch (area) {
      NationwideArea() => l10n.regionNationwide,
      CurrentArea(:final code) =>
        directory.byCode(code)?.fullName ?? l10n.regionCurrent,
      SavedArea(:final code) => directory.byCode(code)?.fullName ?? '',
    };

    final weatherState = context
        .select<
          HomeWeatherController,
          ({String? areaCode, String? weatherCode, WeatherRealtime? weather})
        >(
          (controller) => (
            areaCode: controller.areaCode,
            weatherCode: controller.weatherCode,
            weather: controller.weather,
          ),
        );
    // A reading from a previous area is held while the new one loads (never
    // blanking the sheet), but it must not be shown as the new area's — only
    // data belonging to the currently selected township passes through here.
    final realtime = weatherState.weatherCode == weatherState.areaCode
        ? weatherState.weather
        : null;
    final data = realtime?.data;
    final temp = data?.temperature;
    final humidity = data?.humidity;
    final rain = data?.rain;
    // The condition icon follows the station's code via the shared table; the
    // cloud placeholder only shows before the first reading arrives.
    final weather = data == null
        ? null
        : weatherVisual(
            data.weather,
            data.weatherCode,
            colors,
            isNight: isNightAt(AppTime.utc),
          );
    final conditionIcon = weather?.$1 ?? cloudy;
    final conditionAccent = weather?.$2 ?? secondary;

    // 全國 has no township weather — name only. 所在地 without GPS: say so
    // instead of a dashed reading row.
    final nationwide = area is NationwideArea;
    final currentUnavailable = area is CurrentArea && area.code == null;

    // Name is the hero — larger when full-bleed (below typhoon's display*).
    final nameStyle =
        (expanded
                ? theme.textTheme.headlineLarge
                : theme.textTheme.headlineSmall)
            ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            );
    final tempStyle =
        (expanded ? theme.textTheme.displayLarge : theme.textTheme.displaySmall)
            ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              height: 1,
            );
    final unitStyle =
        (expanded ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium)
            ?.copyWith(color: secondary);
    final iconSize = expanded ? 80.0 : 48.0;

    return Padding(
      // Extra band when flush so the hero isn't jammed under the status inset.
      padding: EdgeInsets.only(top: expanded ? AppSpacing.md : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            curve: Curves.easeOutCubic,
            style: nameStyle ?? const TextStyle(),
            child: Text(areaName),
          ),
          if (realtime case final current?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.weatherDataTime(
                current.station.name,
                _clockFormat.format(
                  AppTime.taipei(
                    DateTime.fromMillisecondsSinceEpoch(
                      current.time * 1000,
                      isUtc: true,
                    ),
                  ),
                ),
              ),
              style:
                  (expanded
                          ? theme.textTheme.labelMedium
                          : theme.textTheme.labelSmall)
                      ?.copyWith(color: secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!nationwide) ...[
            SizedBox(height: expanded ? AppSpacing.xl : AppSpacing.lg),
            if (currentUnavailable)
              Row(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: expanded ? 24 : 20,
                    color: secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.regionCurrentUnavailable,
                      style:
                          (expanded
                                  ? theme.textTheme.bodyLarge
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(color: secondary),
                    ),
                  ),
                ],
              )
            else if (expanded)
              // Full-screen: temp as a full-width hero, metrics in a row below —
              // fills the band the way [_StationHero] grows the reading.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        conditionIcon,
                        size: iconSize,
                        color: conditionAccent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: temp?.toStringAsFixed(1) ?? '—',
                              style: tempStyle,
                            ),
                            TextSpan(text: '°C', style: unitStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: l10n.weatherPrecipitation,
                          value: rain == null
                              ? '—'
                              : '${rain.toStringAsFixed(1)} mm',
                          foreground: foreground,
                          secondary: secondary,
                          expanded: true,
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: l10n.weatherHumidity,
                          value: humidity == null ? '—' : '$humidity%',
                          foreground: foreground,
                          secondary: secondary,
                          expanded: true,
                        ),
                      ),
                    ],
                  ),
                  if (realtime case final current?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    // Below the left-hand (precipitation) metric — a quiet
                    // path to the same station on the map, shown only when the
                    // sheet is flush so a collapsed header stays uncluttered.
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => _openNearestStationOnMap(context, current),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs / 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.homeViewOnMap,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: foreground,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left 2/3 — condition icon + temperature.
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          conditionIcon,
                          size: iconSize,
                          color: conditionAccent,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: temp?.toStringAsFixed(1) ?? '—',
                                style: tempStyle,
                              ),
                              TextSpan(text: '°C', style: unitStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right 1/3 — precipitation over humidity.
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Metric(
                          label: l10n.weatherPrecipitation,
                          // A missing reading is a dash, never a fabricated
                          // 0.0 — "no rain" and "no data" must not match.
                          value: rain == null
                              ? '—'
                              : '${rain.toStringAsFixed(1)} mm',
                          foreground: foreground,
                          secondary: secondary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Metric(
                          label: l10n.weatherHumidity,
                          value: humidity == null ? '—' : '$humidity%',
                          foreground: foreground,
                          secondary: secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// A small label over a prominent value (e.g. "Precipitation" / "0.0 mm").
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.foreground,
    required this.secondary,
    this.expanded = false,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color secondary;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              (expanded
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.labelMedium)
                  ?.copyWith(color: secondary),
        ),
        Text(
          value,
          style:
              (expanded
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Opens the map tab on the temperature layer, focused on [realtime]'s station —
/// the same nearest station the header's reading came from (resolved against the
/// township centre / GPS fix by the repository). The one-shot station hand-off
/// switches the overlay, frames the station, and opens its sheet.
void _openNearestStationOnMap(BuildContext context, WeatherRealtime realtime) {
  context.read<MapStationHandoff>().request(
    layerId: 'temperature',
    stationId: realtime.id,
    latitude: realtime.station.latitude,
    longitude: realtime.station.longitude,
  );
  context.goNamed(AppRoutes.map);
}
