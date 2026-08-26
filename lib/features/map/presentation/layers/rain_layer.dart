/// The rainfall station layer — dots coloured by accumulation (mm) over a
/// selectable window (`now` / `10m` / `1h` / …), tap → trend sheet.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/map/presentation/layers/rain_color_scale.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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

/// Localised labels for [RainColorScale].
extension RainColorScaleL10n on RainColorScale {
  String label(AppLocalizations l10n) => switch (this) {
    RainColorScale.fine => l10n.rainScaleFine,
    RainColorScale.coarse => l10n.rainScaleCoarse,
  };
}

/// Shares [WeatherStationLayer]'s dots/sheet/trend machinery; only the value
/// source (the accumulation window) and its chrome differ.
class RainMapLayer
    extends WeatherStationLayer<RainSnapshot, RainObservation, RainTrend> {
  RainMapLayer(super.repository);

  /// Selected accumulation window.
  ///
  /// One hour, not `now`: the day-so-far total answers "has it rained", which
  /// the forecast already says, while the last hour answers "is it raining
  /// hard right now" — the question a rainfall map is opened for.
  final ValueNotifier<RainInterval> interval = ValueNotifier(
    RainInterval.hour1,
  );

  /// Threshold table the ramp is read against.
  ///
  /// Changing the window re-suggests the scale that suits it, and an explicit
  /// choice holds only until the next window change. Sticking to a manual
  /// choice forever would silently flatten a 3-day total to one grey blob for
  /// anyone who once picked the fine scale to inspect an hour.
  final ValueNotifier<RainColorScale> colorScale = ValueNotifier(
    RainColorScale.defaultFor(RainInterval.hour1),
  );

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

  /// CWA banded precipitation scale (mm) at the selected [colorScale].
  @override
  List<(double, String)> get colorStops => [
    for (final (at, hex) in colorScale.value.stops) (at, hex.vision),
  ];

  /// The published scale is a table of categories, not a gradient.
  @override
  bool get bandedColors => true;

  /// The legend draws as a gradient, unlike the dots and sheet reading above —
  /// matching the QPESUMS forecast legend's look, since both are precipitation
  /// scales shown on the same map.
  @override
  bool get legendBanded => false;

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
  Listenable get chromeListenable => Listenable.merge([interval, colorScale]);

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
  ///
  /// The scale follows: a window change is the moment an explicit scale choice
  /// stops being informed, because it was made about a different range.
  Future<void> setInterval(RainInterval next) async {
    if (interval.value == next) return;
    interval.value = next;
    colorScale.value = RainColorScale.defaultFor(next);
    await _repaint();
  }

  /// Switches the threshold table, keeping the window.
  Future<void> setColorScale(RainColorScale next) async {
    if (colorScale.value == next) return;
    colorScale.value = next;
    await _repaint();
  }

  /// Re-pushes the source and the value ramp after a window/scale change.
  ///
  /// The dots carry their value in the GeoJSON but take their colour from the
  /// layer's paint expression, so a scale change has to re-assert the ramp too
  /// — the feature data alone is unchanged and would repaint identically.
  Future<void> _repaint() async {
    final map = controller;
    if (map == null) return;
    try {
      await map.setGeoJsonSource(sourceId, geoJson);
      await applyColorRamp(map);
    } catch (_) {
      // Source gone (layer torn down) — next [render] rebuilds it.
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
      listenable: Listenable.merge([
        interval,
        colorScale,
        showTownLabels,
        showTerrain,
      ]),
      builder: (context, _) {
        final current = interval.value;
        final scale = colorScale.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.timelapse_outlined,
            // The window changes what every dot on the map means, so it is read
            // far more often than it is set — a bare icon made the answer cost
            // a menu open. Same chip affordance and height as every other
            // layer's menu, so the compass (parked under the chip band) lines
            // up across layers.
            label: current.label(l10n),
            tooltip: l10n.rainIntervalMenu,
            active: current != RainInterval.hour1,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                MapBasemapControlRows(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                  showTerrain: showTerrain,
                  onShowTerrainChanged: onShowTerrainChanged,
                ),
                const MapMenuDivider(),
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
                SectionHeader(l10n.rainScaleSection),
                for (final option in RainColorScale.values)
                  MenuItemButton(
                    onPressed: () => setColorScale(option),
                    trailingIcon: option == scale
                        ? Icon(Icons.check, size: 18, color: colors.primary)
                        : null,
                    child: Text(option.label(l10n)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
