/// Home-sheet 24h township forecast — redesign of the legacy strip.
library;

import 'dart:ui' show lerpDouble;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/solar_time.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
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
  /// Height of the fully grown temperature curve. Not text-scaled — it is a
  /// chart, and its readable size comes from the width it is drawn across.
  static const double _sparklineHeight = 36;

  /// Expansion at which the detail band snaps open. Halfway through the
  /// reveal, so the same pull that grows the curve carries the band with it,
  /// and the band never sits on a threshold the scroll cannot cross —
  /// `HomeContent` normalises [HomeForecastSection.expansion] against the
  /// scroll range that actually exists, so 0.5 is always half a pull away.
  static const double _detailOpenAt = 0.5;

  int _selected = 0;
  WeatherForecast? _seriesForecast;
  _ForecastTemperatureSeries? _series;
  int _sunMinute = -1;
  ({double sunrise, double sunset})? _sunlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final expansion = widget.expansion.clamp(0.0, 1.0);
    final controller = context.read<HomeWeatherController>();
    final code = context.select<HomeWeatherController, String?>(
      (value) => value.areaCode,
    );
    final forecast = context.select<HomeWeatherController, WeatherForecast?>(
      (value) => value.forecast,
    );
    final loading = context.select<HomeWeatherController, bool>(
      (value) => value.loading,
    );
    final forecastFailure = context.select<HomeWeatherController, Failure?>(
      (value) => value.forecastFailure,
    );
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

    if (code == null) {
      return _Shell(
        color: cardColor,
        child: Text(
          l10n.homeForecastUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
        ),
      );
    }

    if (forecast == null) {
      if (loading) {
        return _Shell(
          color: cardColor,
          child: SizedBox(
            height: lerpDouble(120, 168, expansion)!,
            child: Center(child: InlineLoading(color: secondary)),
          ),
        );
      }
      if (forecastFailure != null) {
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
    final series = _temperatureSeries(forecast);
    final sunlight = _sunTimesFor(AppTime.utc);
    final temps = series.temps;
    final minTemp = series.min;
    final maxTemp = series.max;
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
              // Flexible, not a bare [Text]: a Row lays its non-flex children
              // out unbounded, so at a large text step this one grew past the
              // width left over and the whole title row overflowed to the
              // right. Sharing the row with the title lets it wrap onto a
              // second line instead — the high and the low are numbers, and a
              // number that is ellipsised is worse than a number on its own
              // line. At every ordinary text size it still fits on one.
              Flexible(
                child: Text(
                  l10n.homeForecastHighLow(
                    maxTemp.round().toString(),
                    minTemp.round().toString(),
                  ),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge?.copyWith(color: secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The sparkline reveals with [expansion] — the summary card shows
          // only the title + hour chips, and pulling the sheet up grows this
          // same card into its full height. Grown by handing the painter a
          // shorter box, never by clipping a full-height one: the painter maps
          // the series onto whatever height it is given, so every fraction is
          // a whole curve. The scroll can rest at any fraction, and a clipped
          // chart parked at 0.7 reads as a chart with its bottom sliced off.
          Opacity(
            opacity: expansion,
            child: SizedBox(
              height: _sparklineHeight * expansion,
              width: double.infinity,
              child: CustomPaint(
                painter: _TempSparklinePainter(
                  temps: temps,
                  min: minTemp,
                  max: maxTemp,
                  selected: selected,
                  line: colors.primary,
                  fill: colors.primary.withValues(alpha: 0.18),
                  mark: foreground,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md * expansion),
          // The strip is exactly as tall as the tallest chip wants to be, not
          // a fixed height the chips are expected to fit inside. Every line in
          // a chip grows with the text-size setting while the icon does not,
          // so no constant is right at every step: 108 fit until 特大, where
          // the chips ran 16 px over it and the rain chance was cut in half.
          // The intrinsic pass costs one extra layout of a row of ~24 chips of
          // three short strings each.
          IntrinsicHeight(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  for (final (index, p) in points.indexed)
                    Builder(
                      builder: (context) {
                        final hour = _hourNumber(p.time);
                        final (icon, accent) = weatherVisual(
                          p.weather,
                          p.weatherCode,
                          colors,
                          // Per hour, not per row: a clear 02:00 chip must show
                          // a moon while the 14:00 chip beside it shows a sun.
                          isNight:
                              hour < sunlight.sunrise ||
                              hour >= sunlight.sunset,
                        );
                        return _HourChip(
                          time: l10n.chartHourLabel(hour),
                          icon: icon,
                          iconColor: accent ?? secondary,
                          temp: '${p.temperature.round()}°',
                          pop: l10n.homeForecastPop(p.pop.toString()),
                          selected: index == selected,
                          foreground: foreground,
                          secondary: secondary,
                          selectedFill: colors.primary.withValues(alpha: 0.16),
                          onTap: () => setState(() => _selected = index),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          // Snapped open, not scroll-linked like the sparkline above: this band
          // is text, and a fraction of a line of text is a line cut in half.
          // The scroll rests wherever the finger leaves it, so a scroll-linked
          // clip here parks a sliced line on screen for as long as the user
          // stays — which is exactly what it used to do. It crosses
          // [_detailOpenAt] once and animates to its own full height.
          AnimatedSize(
            duration: AppMotion.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expansion < _detailOpenAt
                ? const SizedBox(width: double.infinity)
                : _DetailBand(
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

  _ForecastTemperatureSeries _temperatureSeries(WeatherForecast forecast) {
    final cached = _series;
    if (identical(_seriesForecast, forecast) && cached != null) return cached;

    final points = forecast.forecast;
    final temps = List<double>.filled(points.length, 0, growable: false);
    var min = points.first.temperature;
    var max = min;
    for (var i = 0; i < points.length; i++) {
      final temperature = points[i].temperature;
      temps[i] = temperature;
      if (temperature < min) min = temperature;
      if (temperature > max) max = temperature;
    }
    final series = _ForecastTemperatureSeries(temps, min, max);
    _seriesForecast = forecast;
    _series = series;
    return series;
  }

  /// The hour glyphs all share one sunrise/sunset pair. Cache it to the minute
  /// because the sheet rebuilds this section at frame rate while dragging,
  /// whereas the solar result moves by far less than a minute per minute.
  ({double sunrise, double sunset}) _sunTimesFor(DateTime utc) {
    final minute = utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;
    final cached = _sunlight;
    if (minute == _sunMinute && cached != null) return cached;
    final sunlight = sunTimes(utc);
    _sunMinute = minute;
    _sunlight = sunlight;
    return sunlight;
  }
}

class _ForecastTemperatureSeries {
  const _ForecastTemperatureSeries(this.temps, this.min, this.max);

  final List<double> temps;
  final double min;
  final double max;
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
    required this.min,
    required this.max,
    required this.selected,
    required this.line,
    required this.fill,
    required this.mark,
  });

  final List<double> temps;
  final double min;
  final double max;
  final int selected;
  final Color line;
  final Color fill;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.isEmpty) return;
    final span = (max - min).abs() < 0.01 ? 1.0 : max - min;
    final n = temps.length;
    Offset at(int i) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final y = size.height * (1 - ((temps[i] - min) / span).clamp(0.0, 1.0));
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

  /// The state owns one series per immutable forecast, so identity means the
  /// values are unchanged and avoids a 24-element comparison on every scroll
  /// frame.
  @override
  bool shouldRepaint(covariant _TempSparklinePainter old) =>
      old.selected != selected ||
      old.line != line ||
      old.fill != fill ||
      old.mark != mark ||
      old.min != min ||
      old.max != max ||
      !identical(old.temps, temps);
}
