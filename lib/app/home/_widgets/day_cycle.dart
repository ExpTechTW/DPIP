/// A card widget displaying the sun's daily arc with sunrise and sunset times.
library;

import 'dart:math';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A card that renders the sun's arc from sunrise to sunset.
///
/// Shows the full day arc as a track, with the elapsed portion highlighted in
/// amber up to the sun's current position. Sunrise time appears bottom-left,
/// sunset time bottom-right.
class DayCycle extends StatelessWidget {
  const DayCycle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: Padding(
          padding: .all(16),
          child: Column(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              Row(
                spacing: 4,
                children: [
                  Icon(Symbols.wb_twilight_rounded, fill: 1, color: Colors.orangeAccent),
                  BodyText.large('日出日落', weight: .bold),
                ],
              ),
              const SizedBox(height: 16),
              _SunCycleGraph(
                sunrise: const TimeOfDay(hour: 5, minute: 30),
                sunset: const TimeOfDay(hour: 18, minute: 30),
                now: TimeOfDay.now(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunCycleGraph extends StatelessWidget {
  final TimeOfDay now;
  final TimeOfDay sunrise;
  final TimeOfDay sunset;

  const _SunCycleGraph({
    required this.sunrise,
    required this.sunset,
    required this.now,
  });

  String _formatTime(TimeOfDay t) {
    return '${t.hour}:${t.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _SunArcPainter(
              now: now,
              sunrise: sunrise,
              sunset: sunset,
              primaryColor: context.colors.primary,
              surfaceVariantColor: context.colors.outlineVariant,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  spacing: 4,
                  children: [
                    Icon(
                      Symbols.sunny_rounded,
                      fill: 1,
                      size: 20,
                      color: Colors.orangeAccent,
                    ),
                    LabelText.medium(
                      '日出',
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
                BodyText.large(
                  _formatTime(sunrise),
                  weight: .bold,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: .end,
              children: [
                Row(
                  spacing: 4,
                  children: [
                    Icon(
                      Symbols.wb_twilight_rounded,
                      fill: 1,
                      size: 20,
                      color: Colors.indigoAccent,
                    ),
                    LabelText.medium(
                      '日落',
                      color: context.colors.onSurfaceVariant,
                    ),
                  ],
                ),
                BodyText.large(
                  _formatTime(sunset),
                  weight: .bold,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SunArcPainter extends CustomPainter {
  final TimeOfDay now;
  final Color primaryColor;
  final TimeOfDay sunrise;
  final TimeOfDay sunset;
  final Color surfaceVariantColor;

  const _SunArcPainter({
    required this.now,
    required this.sunrise,
    required this.sunset,
    required this.primaryColor,
    required this.surfaceVariantColor,
  });

  /// Builds a sine arch path from x=0 to x=[maxT/π × width].
  ///
  /// [maxT] is the upper bound of the parameter t ∈ [0, π].
  Path _buildSinePath(double maxT, double width, double cy, double peakHeight) {
    const steps = 100;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = (i / steps) * maxT;
      final x = (t / pi) * width;
      final y = cy - peakHeight * sin(t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  double _toMinutes(TimeOfDay t) => t.hour * 60.0 + t.minute;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 20.0;
    const bottomPad = 8.0;
    final width = size.width;
    final cy = size.height - bottomPad;
    final peakHeight = cy - topPad;

    final sunriseMin = _toMinutes(sunrise);
    final sunsetMin = _toMinutes(sunset);
    final nowMin = _toMinutes(now);
    final progress = ((nowMin - sunriseMin) / (sunsetMin - sunriseMin)).clamp(0.0, 1.0);

    final fullPath = _buildSinePath(pi, width, cy, peakHeight);

    // Sky gradient: fills the dome under the arc.
    final skyPath = _buildSinePath(pi, width, cy, peakHeight)
      ..lineTo(width, cy)
      ..lineTo(0, cy)
      ..close();
    canvas.drawPath(
      skyPath,
      Paint()
        ..shader = LinearGradient(
          begin: .topCenter,
          end: .bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.12),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, topPad, width, peakHeight)),
    );

    // Horizon line.
    canvas.drawLine(
      Offset(0, cy),
      Offset(width, cy),
      Paint()
        ..color = surfaceVariantColor
        ..strokeWidth = 1,
    );

    // Full arc track (faint).
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = surfaceVariantColor
        ..strokeWidth = 2
        ..style = .stroke
        ..strokeCap = .round,
    );

    // Elapsed arc (amber).
    if (progress > 0) {
      canvas.drawPath(
        _buildSinePath(pi * progress, width, cy, peakHeight),
        Paint()
          ..color = Colors.amber
          ..strokeWidth = 3
          ..style = .stroke
          ..strokeCap = .round,
      );
    }

    // Sun position along the sine curve.
    final sunOffset = Offset(
      progress * width,
      cy - peakHeight * sin(pi * progress),
    );

    // Glow layers.
    canvas.drawCircle(sunOffset, 18, Paint()..color = Colors.amber.withValues(alpha: 0.1));
    canvas.drawCircle(sunOffset, 12, Paint()..color = Colors.amber.withValues(alpha: 0.2));

    // Sun disc.
    canvas.drawCircle(sunOffset, 7, Paint()..color = Colors.amber);
    canvas.drawCircle(
      sunOffset,
      7,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = .stroke
        ..strokeWidth = 1.5,
    );

    // Endpoint dots at the horizon.
    canvas.drawCircle(Offset(0, cy), 3.5, Paint()..color = Colors.amber.withValues(alpha: 0.7));
    canvas.drawCircle(
      Offset(width, cy),
      3.5,
      Paint()..color = surfaceVariantColor.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_SunArcPainter old) {
    return old.now != now ||
        old.sunrise != sunrise ||
        old.sunset != sunset ||
        old.primaryColor != primaryColor ||
        old.surfaceVariantColor != surfaceVariantColor;
  }
}
