/// The report map's marker artwork, drawn locally instead of shipped as PNGs.
///
/// The legacy app bundled 19 PNGs (`intensity-1`…`intensity-9`, a `-dark`
/// variant of each, and `cross`). Rendering them on the fly with the same
/// geometry keeps the map visually identical while dropping the assets — and
/// the badge colours come from [IntensityColors], so the markers can never
/// drift from the legend. Each badge is a full-bleed rounded square (white on
/// light maps, black on dark) holding a smaller rounded square in the
/// intensity colour, with the level digit — white, or black on the
/// yellow/orange badges (4–5) for contrast. `cross` is the red × marker for
/// station positions.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/painting.dart';

/// Renders the report-map marker icons as PNG bytes for
/// `MapLibreMapController.addImage`.
abstract final class IntensityIconRenderer {
  /// The icon names, matching the legacy PNG filenames.
  static final List<String> names = [
    'cross',
    for (var i = 1; i <= 9; i++) 'intensity-$i',
    for (var i = 1; i <= 9; i++) 'intensity-$i-dark',
  ];

  /// Renders every icon in [names] to PNG bytes, cached after the first call.
  static Future<Map<String, Uint8List>> renderAll() async {
    return _cache ??= await _renderAll();
  }

  static Future<Map<String, Uint8List>> _renderAll() async {
    final icons = <String, Uint8List>{};
    for (final name in names) {
      icons[name] = await _paintAndEncode(name);
    }
    return icons;
  }

  static Map<String, Uint8List>? _cache;

  static Future<Uint8List> _paintAndEncode(String name) async {
    final size = name == 'cross' ? 96 : 64;
    final recorder = ui.PictureRecorder();
    _paint(Canvas(recorder), size.toDouble(), name);
    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Renders one icon by name (see [names]) to PNG bytes, cached after the
  /// first call.
  static Future<Uint8List> render(String name) async {
    final icons = await renderAll();
    return icons[name]!;
  }

  static void _paint(Canvas canvas, double size, String name) {
    if (name == 'cross') {
      _paintCross(canvas, size);
      return;
    }
    final level = int.parse(name.split('-')[1]);
    final dark = name.endsWith('-dark');
    final bounds = Rect.fromLTWH(0, 0, size, size);
    // Outer shell first, then the badge, so the shell shows as a rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(size * 0.22)),
      Paint()..color = dark ? _black : _white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bounds.deflate(size * 0.08),
        Radius.circular(size * 0.16),
      ),
      Paint()..color = IntensityColors.discrete(level),
    );
    final digit = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          color: level == 4 || level == 5 ? _black : _white,
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    digit.paint(
      canvas,
      bounds.center - Offset(digit.width / 2, digit.height / 2),
    );
  }

  /// The red × station marker: a white outline stroke under the red body so it
  /// stays visible on any basemap, exactly like the legacy PNG.
  static void _paintCross(Canvas canvas, double size) {
    final margin = 8.0;
    final topLeft = Offset(margin, margin);
    final bottomRight = Offset(size - margin, size - margin);
    final topRight = Offset(size - margin, margin);
    final bottomLeft = Offset(margin, size - margin);
    for (final (start, end) in [
      (topLeft, bottomRight),
      (topRight, bottomLeft),
    ]) {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = _white
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.38,
      );
    }
    for (final (start, end) in [
      (topLeft, bottomRight),
      (topRight, bottomLeft),
    ]) {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFF2C2C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.30,
      );
    }
  }

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);
}
