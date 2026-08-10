/// Frosted dropdown beside the layer switcher — typhoon overlay toggles,
/// grouped by storm band, weather underlay, and optional overlays.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_storm_band.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens a categorised overlay menu.
class TyphoonOverlayMenu extends StatelessWidget {
  const TyphoonOverlayMenu({
    super.key,
    required this.layer,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
  });

  final TyphoonMapLayer layer;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  static const Color _l7 = Color(0xFF9C27B0);
  static const Color _l10 = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.showProbability,
        layer.showForecastCallouts,
        layer.showWarningAreas,
        layer.stormBand,
        layer.weatherOverlay,
        layer.showScanRange,
        layer.showCountyOutline,
        layer.showTownOutline,
        showTownLabels,
      ]),
      builder: (context, _) {
        final band = layer.stormBand.value;
        final showProb = layer.showProbability.value;
        final showCallouts = layer.showForecastCallouts.value;
        final showWarn = layer.showWarningAreas.value;
        final weather = layer.weatherOverlay.value;
        final isRadar = weather == TyphoonWeatherOverlay.radar;
        final showRange = layer.showScanRange.value;
        final showCounty = layer.showCountyOutline.value;
        final showTown = layer.showTownOutline.value;
        final showLabels = showTownLabels.value;
        final active =
            showProb ||
            !showCallouts ||
            showWarn ||
            !showLabels ||
            band != TyphoonStormBand.level7 ||
            // Any underlay at all is already a deviation, and the radar chrome
            // only exists while there is one — so the marker is on for every
            // state those toggles can be seen in, and testing them here would
            // never change the answer.
            weather != TyphoonWeatherOverlay.none;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) {
            return MapChipButton(
              icon: Icons.tune,
              tooltip: l10n.typhoonOverlayMenuTooltip,
              active: active,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.typhoonOverlaySectionStorm),
                _StormBandRow(
                  selected: band == TyphoonStormBand.level7,
                  accent: _l7,
                  title: l10n.typhoonLegendCircle15,
                  subtitle: l10n.typhoonOverlayStormBandSubtitle,
                  tooltip: l10n.typhoonOverlayStormL7Tooltip,
                  onTap: () => layer.setStormBand(TyphoonStormBand.level7),
                ),
                _StormBandRow(
                  selected: band == TyphoonStormBand.level10,
                  accent: _l10,
                  title: l10n.typhoonLegendCircle25,
                  subtitle: l10n.typhoonOverlayStormBandSubtitle,
                  tooltip: l10n.typhoonOverlayStormL10Tooltip,
                  onTap: () => layer.setStormBand(TyphoonStormBand.level10),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.typhoonOverlaySectionWeather),
                _WeatherRow(
                  selected: weather == TyphoonWeatherOverlay.none,
                  icon: Icons.layers_clear_outlined,
                  title: l10n.typhoonOverlayWeatherNone,
                  tooltip: l10n.typhoonOverlayWeatherNoneTooltip,
                  onTap: () =>
                      layer.setWeatherOverlay(TyphoonWeatherOverlay.none),
                ),
                _WeatherRow(
                  selected: weather == TyphoonWeatherOverlay.radar,
                  icon: Icons.radar_outlined,
                  title: l10n.mapLayerRadar,
                  subtitle: l10n.typhoonOverlayWeatherHint,
                  tooltip: l10n.typhoonOverlayWeatherRadarTooltip,
                  onTap: () =>
                      layer.setWeatherOverlay(TyphoonWeatherOverlay.radar),
                ),
                _WeatherRow(
                  selected: weather == TyphoonWeatherOverlay.satellite,
                  icon: Icons.satellite_alt_outlined,
                  title: l10n.mapLayerSatellite,
                  subtitle: l10n.typhoonOverlayWeatherHint,
                  tooltip: l10n.typhoonOverlayWeatherSatelliteTooltip,
                  onTap: () =>
                      layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite),
                ),
                // Radar's own chrome, offered only while radar is the underlay —
                // a coverage boundary over IR would bound an instrument that is
                // not on screen, and the base style's borders only disappear
                // under the echo.
                if (isRadar) ...[
                  MapMenuToggleRow(
                    selected: showRange,
                    icon: Icons.crop_free_outlined,
                    title: l10n.radarScanRange,
                    subtitle: l10n.radarScanRangeHint,
                    tooltip: l10n.radarScanRangeSubtitle,
                    onTap: () => layer.setShowScanRange(!showRange),
                  ),
                  MapMenuToggleRow(
                    selected: showCounty,
                    icon: Icons.map_outlined,
                    title: l10n.radarCountyOutline,
                    subtitle: l10n.radarCountyOutlineHint,
                    tooltip: l10n.radarCountyOutlineSubtitle,
                    onTap: () => layer.setShowCountyOutline(!showCounty),
                  ),
                  MapMenuToggleRow(
                    selected: showTown,
                    icon: Icons.grid_on_outlined,
                    title: l10n.radarTownOutline,
                    subtitle: l10n.radarTownOutlineHint,
                    tooltip: l10n.radarTownOutlineSubtitle,
                    onTap: () => layer.setShowTownOutline(!showTown),
                  ),
                ],
                const MapMenuDivider(),
                SectionHeader(l10n.typhoonOverlaySectionExtra),
                MapMenuToggleRow(
                  selected: showCallouts,
                  icon: Icons.info_outline,
                  title: l10n.typhoonOverlayForecastCallouts,
                  tooltip: l10n.typhoonOverlayForecastCalloutsTooltip,
                  onTap: () => layer.setShowForecastCallouts(!showCallouts),
                ),
                MapMenuToggleRow(
                  selected: showProb,
                  icon: Icons.bubble_chart_outlined,
                  title: l10n.typhoonLegendProbability,
                  subtitle: l10n.typhoonOverlayProbabilityHint,
                  tooltip: l10n.typhoonOverlayProbabilityTooltip,
                  onTap: () => layer.setShowProbability(!showProb),
                ),
                MapMenuToggleRow(
                  selected: showWarn,
                  icon: Icons.warning_amber_outlined,
                  title: l10n.typhoonLegendWarningAreas,
                  tooltip: l10n.typhoonOverlayWarningTooltip,
                  onTap: () => layer.setShowWarningAreas(!showWarn),
                ),
                const MapMenuDivider(),
                SectionHeader(l10n.mapOverlaySectionMap),
                MapTownLabelsRow(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StormBandRow extends StatelessWidget {
  const _StormBandRow({
    required this.selected,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final Color accent;
  final String title;
  final String subtitle;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: MenuItemButton(
        onPressed: onTap,
        style: MapChipButton.rowStyle(
          selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _BandSwatch(accent: accent, selected: selected),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? accent : colors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fill + dashed avg preview for a storm band.
class _BandSwatch extends StatelessWidget {
  const _BandSwatch({required this.accent, required this.selected});

  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: selected ? 0.28 : 0.16),
              border: Border.all(color: accent, width: 1.5),
            ),
          ),
          CustomPaint(
            size: const Size(26, 26),
            painter: _DashedCirclePainter(
              color: accent.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 0.5;
    const dash = 2.2;
    const gap = 1.6;
    var angle = 0.0;
    while (angle < 6.2832) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        angle,
        dash / radius,
        false,
        paint,
      );
      angle += (dash + gap) / radius;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Radio row for weather underlay (none / radar / IR).
class _WeatherRow extends StatelessWidget {
  const _WeatherRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.tooltip,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: MenuItemButton(
        onPressed: onTap,
        style: MapChipButton.rowStyle(
          selected
              ? colors.primaryContainer.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? colors.primary : colors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
