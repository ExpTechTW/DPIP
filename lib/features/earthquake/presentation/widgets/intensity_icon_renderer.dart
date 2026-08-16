/// The report map's marker artwork, drawn locally instead of shipped as PNGs.
///
/// The legacy app bundled 19 PNGs (`intensity-1`…`intensity-9`, a `-dark`
/// variant of each, and `cross`). Rendering them on the fly with the same
/// geometry keeps the map visually identical while dropping the assets — and
/// the badge colours come from [IntensityColors], so the markers can never
/// drift from the legend. Each badge is a full-bleed rounded square (white on
/// light maps, black on dark) holding a smaller rounded square in the
/// intensity colour, with [Intensity.label]'s level label (`1`…`4`, then
/// `5⁻`/`5⁺`/`6⁻`/`6⁺`/`7`) — white, or black on the yellow/orange badges
/// (4–5) for contrast. `cross` is the red × marker for station positions.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/painting.dart';

/// Renders the report-map marker icons as PNG bytes for
/// `MapLibreMapController.addImage`.
abstract final class IntensityIconRenderer {
  /// The icon names, matching the legacy PNG filenames — plus the two
  /// `-old` 舊制 variants (see [nameFor]): wire `5`/`6` on a pre-2020 report
  /// share their colour with the 新制 `5`/`7` badges but need the plain
  /// `5`/`6` label instead of `5⁻`/`6⁻`.
  static final List<String> names = [
    'cross',
    for (var i = 1; i <= 9; i++) 'intensity-$i',
    for (var i = 1; i <= 9; i++) 'intensity-$i-dark',
    for (final i in [5, 7]) 'intensity-$i-old',
    for (final i in [5, 7]) 'intensity-$i-old-dark',
  ];

  /// The icon name for a town/station's [presentation] — the normal
  /// `intensity-N` family when its label matches [Intensity.label] for that
  /// colour level, or the `-old` variant when [Intensity.displayForReport]'s
  /// pre-2020 舊制 branch remapped the label (wire `5`/`6` → plain `5`/`6`,
  /// not `5⁻`/`6⁻`) — see the class doc.
  static String nameFor(
    IntensityPresentation presentation, {
    required bool useDarkSuffix,
  }) {
    final suffix = useDarkSuffix ? '-dark' : '';
    final isOld =
        presentation.label != Intensity.label(presentation.colorLevel);
    final old = isOld ? '-old' : '';
    return 'intensity-${presentation.colorLevel}$old$suffix';
  }

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

  static Future<Uint8List> _paintAndEncode(String name) async {
    final size = name == 'cross' ? 96 : 64;
    final recorder = ui.PictureRecorder();
    _paint(Canvas(recorder), size.toDouble(), name);
    // Both native handles released once the PNG copy exists — bounded by the
    // byte cache to one bake per icon per run, but 19 leaked rasters is still
    // 19 too many.
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
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
    final parts = name.split('-');
    final level = int.parse(parts[1]);
    final dark = parts.contains('dark');
    final old = parts.contains('old');
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
    // [Intensity.label], not the raw digit: 5–9 are the CWA 新制 5⁻/5⁺/6⁻/6⁺/7
    // levels, not literal "5".."9" — see [IntensityBadge], which renders the
    // same report/map markers' labels correctly. The `-old` variants (see
    // [names]) print the pre-2020 舊制 label instead — same colour, plain
    // digit — matching [Intensity.displayForReport]'s remap.
    final text = old ? _oldScaleLabels[level]! : Intensity.label(level);
    final color = level == 4 || level == 5 ? _black : _white;
    // Shrink-to-fit: this Canvas text has no BuildContext/widget-tree font
    // resolution to fall back on, and a font lacking the superscript ± glyph
    // in 5⁻/5⁺/6⁻/6⁺ can substitute a full-width fallback box for it — so
    // measure at the natural size and back off proportionally rather than
    // assume any fixed size safely fits every label/font combination.
    final maxLabelWidth = size * 0.55;
    var fontSize = size * 0.55;
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
    label.paint(
      canvas,
      bounds.center - Offset(label.width / 2, label.height / 2),
    );
  }

  /// The red × station marker — two crossed rectangles (not a stroked line),
  /// so the four tips come to sharp mitered points and the four inner
  /// notches cut clean to the transparent background, with a white outline
  /// ring (a larger white pair of the same rectangles, underneath) so it
  /// stays visible on any basemap. A stroked line here instead reads as a
  /// rounded blob at small map sizes — [PaintingStyle.stroke]'s flat caps
  /// don't give the same crisp corner a filled rectangle's corner does.
  static void _paintCross(Canvas canvas, double size) {
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.rotate(math.pi / 4);
    // Sized to land each tip inside the canvas (including its white
    // outline) rather than getting a flat cut from the canvas bounds.
    final armLength = size * 0.90;
    final armWidth = size * 0.20;
    final border = size * 0.04;
    void drawArms(double length, double width, Color color) {
      final paint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: length, height: width),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: width, height: length),
        paint,
      );
    }

    drawArms(armLength + border * 2, armWidth + border * 2, _white);
    drawArms(armLength, armWidth, const Color(0xFFFF0000));
    canvas.restore();
  }

  /// Plain-digit labels for the 舊制 `-old` variants, keyed by colour level
  /// — mirrors [Intensity.displayForReport]'s pre-2020 remap (wire `5` →
  /// colour level `5`/label `5`; wire `6` → colour level `7`/label `6`).
  static const Map<int, String> _oldScaleLabels = {5: '5', 7: '6'};

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);
}
