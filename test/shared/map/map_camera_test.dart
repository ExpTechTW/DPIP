import 'dart:math' as math;

import 'package:dpip/shared/map/map_camera.dart';
import 'package:flutter_test/flutter_test.dart';

/// Normalised Web-Mercator Y for [lat] (0 north edge → 1 south edge), mirroring
/// the projection inside [fitBoundsCamera] so the test can reason in screen px.
double mercatorY(double lat) {
  final r = lat * math.pi / 180;
  return 0.5 - math.log(math.tan(math.pi / 4 + r / 2)) / (2 * math.pi);
}

/// The screen-y (px from top) a [lat] lands at for a camera centred on
/// [centerLat] at [zoom], in a viewport [height] tall.
double screenY(double lat, double centerLat, double zoom, double height) {
  final world = 256 * math.pow(2, zoom).toDouble();
  return height / 2 + (mercatorY(lat) - mercatorY(centerLat)) * world;
}

void main() {
  const width = 400.0;
  const height = 900.0;
  // A small square township roughly the size of a Taiwan district.
  const town = <double>[120.20, 23.00, 120.30, 23.10];

  test('fits the bounds within the padded viewport', () {
    final cam = fitBoundsCamera(
      town,
      width: width,
      height: height,
      padding: 24,
    );
    expect(cam.longitude, closeTo(120.25, 1e-9));
    // Zoom is small enough that the bounds span fits inside width − 2·padding.
    final world = 256 * math.pow(2, cam.zoom).toDouble();
    final spanPx = (0.30 - 0.20) / 360 * world;
    expect(spanPx, lessThanOrEqualTo(width - 2 * 24 + 0.5));
  });

  test('clamps zoom to the radar-tile range', () {
    // A degenerate point has an unbounded fit zoom; it must clamp to maxZoom.
    final cam = fitBoundsCamera(
      const [121.0, 25.0, 121.0, 25.0],
      width: width,
      height: height,
      maxZoom: 11,
    );
    expect(cam.zoom, 11);
  });

  test('with no inset the bounds centre lands at the viewport centre', () {
    final cam = fitBoundsCamera(town, width: width, height: height);
    const centreLat =
        23.05; // mercator-midpoint of a small box ≈ arithmetic mid
    final y = screenY(centreLat, cam.latitude, cam.zoom, height);
    expect(y, closeTo(height / 2, 2.0));
  });

  test('a bottom inset lifts the framing into the band above it', () {
    const inset = 300.0; // e.g. a sheet covering the bottom third
    final cam = fitBoundsCamera(
      town,
      width: width,
      height: height,
      bottomInset: inset,
    );
    const centreLat = 23.05;
    final y = screenY(centreLat, cam.latitude, cam.zoom, height);
    // The bounds centre now sits at the centre of the visible band
    // [0, height − inset], i.e. inset/2 above the viewport centre.
    expect(y, closeTo((height - inset) / 2, 2.0));
    expect(y, lessThan(height / 2));
  });
}
