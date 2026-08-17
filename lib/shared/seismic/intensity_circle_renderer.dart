/// The RTS monitor's circular discrete-intensity badge artwork, drawn locally
/// instead of shipped as PNGs — the same rationale as
/// [package:dpip/shared/seismic/intensity_icon_renderer.dart], but circular:
/// during a large event the monitor labels each shaking station with its
/// discrete reading, and that badge stays a circle (real-time instrumental
/// data, never the report/rapid-report square) — see `RtsMapLayer`'s class
/// doc.
///
/// Each badge is a full-bleed circle (white on light maps, black on dark)
/// holding a smaller filled circle in the intensity colour, with
/// [Intensity.label]'s level label — coloured via [IntensityColors.onDiscrete]
/// for contrast, the same rule the badge widgets already use.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/painting.dart';

abstract final class IntensityCircleRenderer {
  /// The icon names: `circle-1`…`circle-9`, plus a `-dark` variant of each.
  /// No `-old` 舊制 forms — unlike a report's wire intensity, a live RTS
  /// reading is never historical, so it's always the current label set.
  static final List<String> names = [
    for (var i = 1; i <= 9; i++) 'circle-$i',
    for (var i = 1; i <= 9; i++) 'circle-$i-dark',
  ];

  /// Renders every icon in [names] to PNG bytes, cached after the first call.
  static Future<Map<String, Uint8List>> renderAll() async {
    if (_cachedFor != AppColorVision.current) _cache = null;
    _cachedFor = AppColorVision.current;
    return _cache ??= await _renderAll();
  }

  static Future<Map<String, Uint8List>> _renderAll() async {
    final icons = <String, Uint8List>{};
    for (final name in names) {
      icons[name] = await _paintAndEncode(name);
    }
    return icons;
  }

  // Baked bitmaps carry the corrected colours painted into them, so they
  // must be re-baked when the setting moves — see [VisionCache].
  static Map<String, Uint8List>? _cache;
  static ColorVision? _cachedFor;

  static const int _size = 64;

  static Future<Uint8List> _paintAndEncode(String name) async {
    final recorder = ui.PictureRecorder();
    _paint(Canvas(recorder), name);
    final picture = recorder.endRecording();
    final image = await picture.toImage(_size, _size);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static void _paint(Canvas canvas, String name) {
    final parts = name.split('-');
    final level = int.parse(parts[1]);
    final dark = parts.contains('dark');
    final size = _size.toDouble();
    final center = Offset(size / 2, size / 2);

    // Outer shell first, then the badge, so the shell shows as a rim — same
    // construction as the square badge, just circular.
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = dark ? _black : _white,
    );
    canvas.drawCircle(
      center,
      size / 2 - size * 0.08,
      Paint()..color = IntensityColors.discrete(level),
    );

    final text = Intensity.label(level);
    final color = IntensityColors.onDiscrete(level);
    // Shrink-to-fit, same reasoning as the square badge: a font lacking the
    // superscript ± glyph in 5⁻/5⁺/6⁻/6⁺ can substitute a full-width
    // fallback box, so measure at the natural size and back off
    // proportionally rather than assume a fixed size always fits.
    final maxLabelWidth = size * 0.5;
    var fontSize = size * 0.5;
    var label = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (label.width > maxLabelWidth) {
      fontSize *= maxLabelWidth / label.width;
      label = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);
}
