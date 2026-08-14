/// A small, flat drawing of the Moon's lit shape at a given phase.
///
/// Deliberately *not* the photoreal shader. At the size a calendar cell gives
/// it, the NASA maps resolve to grey mush and the only thing a reader can
/// actually take from the mark is the shape — so the shape is all this draws,
/// crisply, at any size and with no textures to load. The hero disc on the
/// same page stays photoreal, where the detail is legible and the point.
///
/// The terminator is a true half-ellipse, not an offset circle: the boundary
/// between lit and dark is a great circle seen at an angle, which projects to
/// an ellipse of semi-axis `r·cos(phase)`. The offset-circle shortcut that
/// crescent icons usually use gets the quarters right and everything between
/// them subtly wrong.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class MoonGlyph extends StatelessWidget {
  const MoonGlyph({
    super.key,
    required this.angle,
    required this.size,
    required this.lit,
    required this.dark,
  });

  /// Phase angle in radians: 0 = new, π = full.
  final double angle;

  /// Diameter in logical pixels.
  final double size;

  /// The sunlit face.
  final Color lit;

  /// The unlit face — a rim, so a new moon is still a visible mark rather than
  /// a hole in the layout.
  final Color dark;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _MoonGlyphPainter(angle: angle, lit: lit, dark: dark),
  );
}

class _MoonGlyphPainter extends CustomPainter {
  const _MoonGlyphPainter({
    required this.angle,
    required this.lit,
    required this.dark,
  });

  final double angle;
  final Color lit;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final centre = Offset(radius, radius);
    canvas.drawCircle(centre, radius, Paint()..color = dark);

    final waxing = angle < math.pi;
    final terminator = radius * math.cos(angle);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    // The waning half is the waxing half mirrored — cos is even, so the same
    // path serves both and only the side it sits on changes.
    if (!waxing) canvas.scale(-1, 1);

    final path = Path()
      ..moveTo(0, -radius)
      // Outer edge: the lit limb, top to bottom the long way round.
      ..arcToPoint(
        Offset(0, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      // Inner edge: the terminator, bulging toward the lit side when the Moon
      // is a crescent and away from it when gibbous.
      ..arcToPoint(
        Offset(0, -radius),
        radius: Radius.elliptical(terminator.abs(), radius),
        clockwise: terminator < 0,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = lit);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonGlyphPainter old) =>
      angle != old.angle || lit != old.lit || dark != old.dark;
}
