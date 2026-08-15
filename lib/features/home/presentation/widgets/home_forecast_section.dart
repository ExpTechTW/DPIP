/// Home-sheet 24h township forecast — redesign of the legacy strip.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/solar_time.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 24-hour forecast block under the home header.
///
/// Numbers match legacy meaning: [WeatherForecastPoint.time] (`HH:00`),
/// [WeatherForecastPoint.weather] / code → icon, [WeatherForecastPoint.pop] =
/// rain chance %, [WeatherForecastPoint.temperature] = air temp °C. Layout is
/// new: sparkline + selectable hour chips + a detail band for feels-like /
/// humidity / wind (fields the final legacy strip hid).
///
/// [expansion] animates between the one-glance summary (title + hour chips)
/// and the full card (with the temperature sparkline and detail band). The
/// hero block's card slot uses it to grow the single forecast card into its
/// complete form as the sheet is pulled up — the summary and the full card are
/// one widget, not two.
class HomeForecastSection extends StatefulWidget {
  const HomeForecastSection({
    super.key,
    this.reveal = 0,
    this.sky,
    this.weatherMode = WeatherMode.auto,
    this.expansion = 1,
  });

  /// Weather-backdrop reveal (0→1) — drives glass card opacity only; ink stays
  /// theme on-surface (cards are light plates).
  final double reveal;

  /// The sky colour the card tints itself from — `SkyLutCache.panelAmbient`, or
  /// null when no backdrop is running. The reference's card is a 20 % pane of the sky,
  /// so without one there is nothing for it to be a pane *of* and it falls back
  /// to an opaque plate.
  final Color? sky;

  /// Backdrop sky mode — decides whether card ink goes dark or white as the
  /// card dissolves into the sky.
  final WeatherMode weatherMode;

  /// How fully the card is revealed, `0` (title + hour chips only) → `1` (the
  /// full card, with the temperature sparkline and the feels-like detail
  /// band). The hero slot drives this from the sheet's scroll; cards outside
  /// the hero sit at 1.
  final double expansion;

  @override
  State<HomeForecastSection> createState() => _HomeForecastSectionState();
}

class _HomeForecastSectionState extends State<HomeForecastSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final expansion = widget.expansion.clamp(0.0, 1.0);
    final controller = context.watch<HomeWeatherController>();
    final reveal = widget.reveal;
    final skyIsLight = skyIsLightFrom(widget.sky, widget.weatherMode);
    final foreground = glassOnSurface(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final secondary = glassOnSurfaceVariant(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final cardColor = glassSurface(colors, reveal, sky: widget.sky);

    final code = controller.areaCode;

    if (code == null) {
      return _Shell(
        color: cardColor,
        child: Text(
          l10n.homeForecastUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
        ),
      );
    }

    final forecast = controller.forecast;
    if (forecast == null) {
      if (controller.loading) {
        return _Shell(
          color: cardColor,
          child: SizedBox(
            height: lerpDouble(120, 168, expansion)!,
            child: Center(child: InlineLoading(color: secondary)),
          ),
        );
      }
      if (controller.forecastFailure != null) {
        return _Shell(
          color: cardColor,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeForecastEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
                ),
              ),
              TextButton(
                onPressed: controller.refresh,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final points = forecast.forecast;
    if (points.isEmpty) {
      return _Shell(
        color: cardColor,
        child: Text(
          l10n.homeForecastEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
        ),
      );
    }

    final selected = _selected.clamp(0, points.length - 1);
    final temps = points.map((p) => p.temperature).toList(growable: false);
    final minTemp = temps.reduce(math.min);
    final maxTemp = temps.reduce(math.max);
    final point = points[selected];

    return _Shell(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 18, color: secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.homeForecastTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.homeForecastHighLow(
                  maxTemp.round().toString(),
                  minTemp.round().toString(),
                ),
                style: theme.textTheme.labelLarge?.copyWith(color: secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The sparkline and detail band reveal with [expansion] — the summary
          // card shows only the title + hour chips, and pulling the sheet up
          // grows this same card into its full height. Clipped so the not-yet-
          // revealed parts never bleed over the hour chips below.
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: expansion,
              child: Opacity(
                opacity: expansion,
                child: SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TempSparklinePainter(
                      temps: temps,
                      selected: selected,
                      line: colors.primary,
                      fill: colors.primary.withValues(alpha: 0.18),
                      mark: foreground,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md * expansion),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: points.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final p = points[index];
                final (icon, accent) = weatherVisual(
                  p.weather,
                  p.weatherCode,
                  colors,
                  // Per hour, not per row: a clear 02:00 chip must show a moon
                  // while the 14:00 chip beside it shows a sun.
                  isNight: isNightHour(
                    _hourNumber(p.time).toDouble(),
                    utcDay: AppTime.utc,
                  ),
                );
                final isSelected = index == selected;
                return _HourChip(
                  time: l10n.chartHourLabel(_hourNumber(p.time)),
                  icon: icon,
                  iconColor: accent ?? secondary,
                  temp: '${p.temperature.round()}°',
                  pop: l10n.homeForecastPop(p.pop.toString()),
                  selected: isSelected,
                  foreground: foreground,
                  secondary: secondary,
                  selectedFill: colors.primary.withValues(alpha: 0.16),
                  onTap: () => setState(() => _selected = index),
                );
              },
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: expansion,
              child: Opacity(
                opacity: expansion,
                child: _DetailBand(
                  weather: point.weather,
                  time: point.time,
                  feelsLike: l10n.homeForecastFeelsLike(
                    point.apparentTemp.round().toString(),
                  ),
                  humidity: l10n.homeForecastHumidity(
                    point.humidity.toString(),
                  ),
                  wind: l10n.homeForecastWind(
                    point.wind.direction,
                    point.wind.beaufort.toString(),
                  ),
                  foreground: foreground,
                  secondary: secondary,
                  divider: secondary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `"14:00"` → `14` for [AppLocalizations.chartHourLabel] (`14時`).
  static int _hourNumber(String time) {
    final colon = time.indexOf(':');
    final raw = colon <= 0 ? time : time.substring(0, colon);
    return int.tryParse(raw) ?? 0;
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _HourChip extends StatelessWidget {
  const _HourChip({
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.temp,
    required this.pop,
    required this.selected,
    required this.foreground,
    required this.secondary,
    required this.selectedFill,
    required this.onTap,
  });

  final String time;
  final IconData icon;
  final Color iconColor;
  final String temp;
  final String pop;
  final bool selected;
  final Color foreground;
  final Color secondary;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? selectedFill : Colors.transparent,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          width: 64,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? foreground : secondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Icon(icon, size: 22, color: iconColor),
              Text(
                temp,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                pop,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBand extends StatelessWidget {
  const _DetailBand({
    required this.weather,
    required this.time,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.foreground,
    required this.secondary,
    required this.divider,
  });

  final String weather;
  final String time;
  final String feelsLike;
  final String humidity;
  final String wind;
  final Color foreground;
  final Color secondary;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: weather,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  $time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                _Meta(text: feelsLike, color: secondary),
                _Meta(text: humidity, color: secondary),
                _Meta(text: wind, color: secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
    );
  }
}

/// Soft temperature curve across the 24h series; a mark sits on [selected].
class _TempSparklinePainter extends CustomPainter {
  _TempSparklinePainter({
    required this.temps,
    required this.selected,
    required this.line,
    required this.fill,
    required this.mark,
  });

  final List<double> temps;
  final int selected;
  final Color line;
  final Color fill;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.isEmpty) return;
    final minT = temps.reduce(math.min);
    final maxT = temps.reduce(math.max);
    final span = (maxT - minT).abs() < 0.01 ? 1.0 : maxT - minT;
    final n = temps.length;
    Offset at(int i) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = size.height * (1 - ((temps[i] - minT) / span).clamp(0.0, 1.0));
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(at(n - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final markAt = at(selected.clamp(0, n - 1));
    canvas.drawCircle(markAt, 4, Paint()..color = mark);
    canvas.drawCircle(markAt, 2, Paint()..color = line);
  }

  /// Value comparison, not identity — [temps] arrives as a fresh
  /// `points.map((p) => p.temperature).toList(growable: false)` on every
  /// build, so `old.temps != temps` was unconditionally true and the card's
  /// layer re-rasterised on every scroll frame for 24 numbers that had not
  /// moved. Scalars first so the cheap checks short-circuit the list walk.
  @override
  bool shouldRepaint(covariant _TempSparklinePainter old) =>
      old.selected != selected ||
      old.line != line ||
      old.fill != fill ||
      old.mark != mark ||
      !listEquals(old.temps, temps);
}
