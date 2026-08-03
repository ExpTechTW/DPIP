/// Frosted dropdown beside the layer switcher — typhoon overlay toggles,
/// grouped by storm band, weather underlay, and optional overlays.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_storm_band.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';

/// Compact icon chip that opens a categorised overlay menu.
class TyphoonOverlayMenu extends StatelessWidget {
  const TyphoonOverlayMenu({super.key, required this.layer});

  final TyphoonMapLayer layer;

  static const Color _l7 = Color(0xFF9C27B0);
  static const Color _l10 = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.showProbability,
        layer.showForecastCallouts,
        layer.showWarningAreas,
        layer.stormBand,
        layer.weatherOverlay,
      ]),
      builder: (context, _) {
        final band = layer.stormBand.value;
        final showProb = layer.showProbability.value;
        final showCallouts = layer.showForecastCallouts.value;
        final showWarn = layer.showWarningAreas.value;
        final weather = layer.weatherOverlay.value;
        final active =
            showProb ||
            !showCallouts ||
            showWarn ||
            band != TyphoonStormBand.level7 ||
            weather != TyphoonWeatherOverlay.none;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(
              colors.surfaceContainerHigh,
            ),
            elevation: const WidgetStatePropertyAll(6),
            shadowColor: WidgetStatePropertyAll(
              Colors.black.withValues(alpha: 0.24),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
          ),
          builder: (context, controller, _) {
            return Tooltip(
              message: l10n.typhoonOverlayMenuTooltip,
              child: FrostedSurface(
                borderRadius: AppRadius.small,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: AppRadius.small,
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        Icons.tune,
                        size: 22,
                        color: active
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          menuChildren: [
            _SectionLabel(l10n.typhoonOverlaySectionStorm),
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
            _menuDivider(colors),
            _SectionLabel(l10n.typhoonOverlaySectionWeather),
            _WeatherRow(
              selected: weather == TyphoonWeatherOverlay.none,
              icon: Icons.layers_clear_outlined,
              title: l10n.typhoonOverlayWeatherNone,
              tooltip: l10n.typhoonOverlayWeatherNoneTooltip,
              onTap: () => layer.setWeatherOverlay(TyphoonWeatherOverlay.none),
            ),
            _WeatherRow(
              selected: weather == TyphoonWeatherOverlay.radar,
              icon: Icons.radar_outlined,
              title: l10n.mapLayerRadar,
              subtitle: l10n.typhoonOverlayWeatherHint,
              tooltip: l10n.typhoonOverlayWeatherRadarTooltip,
              onTap: () => layer.setWeatherOverlay(TyphoonWeatherOverlay.radar),
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
            _menuDivider(colors),
            _SectionLabel(l10n.typhoonOverlaySectionExtra),
            _ToggleRow(
              selected: showCallouts,
              icon: Icons.info_outline,
              title: l10n.typhoonOverlayForecastCallouts,
              tooltip: l10n.typhoonOverlayForecastCalloutsTooltip,
              onTap: () => layer.setShowForecastCallouts(!showCallouts),
            ),
            _ToggleRow(
              selected: showProb,
              icon: Icons.bubble_chart_outlined,
              title: l10n.typhoonLegendProbability,
              subtitle: l10n.typhoonOverlayProbabilityHint,
              tooltip: l10n.typhoonOverlayProbabilityTooltip,
              onTap: () => layer.setShowProbability(!showProb),
            ),
            _ToggleRow(
              selected: showWarn,
              icon: Icons.warning_amber_outlined,
              title: l10n.typhoonLegendWarningAreas,
              tooltip: l10n.typhoonOverlayWarningTooltip,
              onTap: () => layer.setShowWarningAreas(!showWarn),
            ),
          ],
        );
      },
    );
  }

  static Widget _menuDivider(ColorScheme colors) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    child: Divider(
      height: 1,
      color: colors.outlineVariant.withValues(alpha: 0.5),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Radio-style row for the L7 / L10 storm-band combo.
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
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
          ),
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            selected
                ? colors.primaryContainer.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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

/// Checkbox-style row for optional overlays.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            selected
                ? colors.primaryContainer.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: SizedBox(
          width: 228,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
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
