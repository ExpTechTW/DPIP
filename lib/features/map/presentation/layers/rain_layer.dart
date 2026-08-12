/// The rainfall station layer — dots coloured by accumulation (mm) over a
/// selectable window (`now` / `10m` / `1h` / …), tap → trend sheet.
library;

import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_terrain_toggle.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Localised labels for [RainInterval] (domain stays Flutter-free).
extension RainIntervalL10n on RainInterval {
  String label(AppLocalizations l10n) => switch (this) {
    RainInterval.now => l10n.rainIntervalNow,
    RainInterval.min10 => l10n.rainInterval10m,
    RainInterval.hour1 => l10n.rainInterval1h,
    RainInterval.hour3 => l10n.rainInterval3h,
    RainInterval.hour6 => l10n.rainInterval6h,
    RainInterval.hour12 => l10n.rainInterval12h,
    RainInterval.hour24 => l10n.rainInterval24h,
    RainInterval.day2 => l10n.rainInterval2d,
    RainInterval.day3 => l10n.rainInterval3d,
  };
}

/// Shares [WeatherStationLayer]'s dots/sheet/trend machinery; only the value
/// source (the accumulation window) and its chrome differ.
class RainMapLayer
    extends WeatherStationLayer<RainSnapshot, RainObservation, RainTrend> {
  RainMapLayer(super.repository);

  /// Selected accumulation window — default matches legacy (`now` = 今日).
  final ValueNotifier<RainInterval> interval = ValueNotifier(RainInterval.now);

  @override
  String get id => 'rain';

  @override
  IconData get icon => Icons.umbrella_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRain;

  @override
  String get unit => 'mm';

  @override
  int get decimals => 1;

  @override
  double? get chartMinY => 0;

  @override
  bool get chartBars => true;

  /// Legacy precipitation colour ramp (mm).
  @override
  List<(double, String)> get colorStops => const [
    (0, '#c2c2c2'),
    (10, '#9cfcff'),
    (30, '#059bff'),
    (50, '#39ff03'),
    (100, '#fffb03'),
    (200, '#ff9500'),
    (300, '#ff0000'),
    (500, '#fb00ff'),
    (1000, '#960099'),
    (2000, '#000000'),
  ];

  @override
  double? valueOf(RainObservation observation) =>
      interval.value.valueOf(observation);

  @override
  List<double?> trendOf(RainTrend trend) => trend.rain;

  /// Dry stations (0 mm) clutter the island at overview; reveal past z8.
  @override
  List<Object>? get featureFilter => const [
    'any',
    <Object>[
      '>',
      <Object>['get', 'value'],
      0,
    ],
    <Object>[
      '>',
      <Object>['zoom'],
      8,
    ],
  ];

  @override
  bool includeInSelection(
    RainObservation observation,
    double value,
    double zoom,
  ) => value > 0 || zoom > 8;

  @override
  Listenable get chromeListenable => interval;

  @override
  Widget? legendHeader(BuildContext context) => Text(
    interval.value.label(AppLocalizations.of(context)),
    style: Theme.of(context).textTheme.labelMedium,
  );

  @override
  String title(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return '${l10n.mapLayerRain} · ${interval.value.label(l10n)}';
  }

  /// Switches the accumulation window and refreshes dots + labels in place.
  Future<void> setInterval(RainInterval next) async {
    if (interval.value == next) return;
    interval.value = next;
    final map = controller;
    if (map != null) {
      try {
        await map.setGeoJsonSource(sourceId, geoJson);
      } catch (_) {
        // Source gone (layer torn down) — next [render] rebuilds it.
      }
    }
  }

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([interval, showTownLabels, showTerrain]),
      builder: (context, _) {
        final current = interval.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.timelapse_outlined,
            tooltip: l10n.rainIntervalMenu,
            // Same chip affordance and height as every other layer's menu, so
            // the compass (parked under the chip band) lines up across layers.
            active: current != RainInterval.now,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.rainIntervalSection),
                for (final option in RainInterval.values)
                  MenuItemButton(
                    onPressed: () => setInterval(option),
                    trailingIcon: option == current
                        ? Icon(Icons.check, size: 18, color: colors.primary)
                        : null,
                    child: Text(option.label(l10n)),
                  ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapTownLabelsRow(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                ),
                MapTerrainRow(
                  showTerrain: showTerrain,
                  onShowTerrainChanged: onShowTerrainChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
