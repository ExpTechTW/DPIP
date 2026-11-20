import 'dart:math' as math;
import 'dart:ui';

import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

typedef StoryCameraLayout = ({Rect mapRegion, Rect anchorRegion});
typedef StoryCamera = ({LatLng target, double zoom});

/// The map fills the canvas, while its symbols belong between the upper
/// Instagram guide and the HUD. The footprint bounds are relative to an
/// anchor and are known before projection, grouping or collision avoidance.
StoryCameraLayout storyCameraLayout({
  required Size canvas,
  required double safeTop,
  required double safeBottom,
  required Rect hud,
  required Rect footprint,
  required double gap,
}) {
  final region = Rect.fromLTRB(
    0,
    safeTop,
    canvas.width,
    math.min(hud.top, canvas.height - safeBottom),
  );
  final side = math.max(-footprint.left, footprint.right) + gap;
  return (
    mapRegion: region,
    anchorRegion: Rect.fromLTRB(
      region.left + side,
      region.top - footprint.top + gap,
      region.right - side,
      region.bottom - footprint.bottom - gap,
    ),
  );
}

/// FULL always fits the epicenter and every drawable report observation.
/// If the minimum zoom is reached, the caller checks actual native anchors
/// against the requested region to distinguish a fit from a constrained map.
StoryCamera fitStoryCamera(EarthquakeReport report, StoryCameraLayout layout) {
  final anchors = layout.anchorRegion;
  if (anchors.isEmpty) {
    throw StateError('Story HUD leaves insufficient room for map symbols');
  }
  if (!isStoryMapCoordinate(report.latitude, report.longitude)) {
    throw const FormatException('Invalid Story epicenter coordinates');
  }
  final bounds = safeFitBounds(
    boundsFromPoints([
      LatLng(report.latitude, report.longitude),
      for (final area in report.list.values)
        for (final observation in area.town.values)
          if (isStoryMapCoordinate(observation.latitude, observation.longitude))
            LatLng(observation.latitude, observation.longitude),
    ])!,
  )!;
  // The shared fitter accepts symmetric horizontal padding and separate
  // top/bottom insets. Together they describe the center rectangle exactly.
  final camera = boundsFitCamera(
    bounds,
    viewport: StoryMapSnapshot.canvas,
    padding: anchors.left,
    topInset: anchors.top - anchors.left,
    bottomInset: StoryMapSnapshot.canvas.height - anchors.bottom - anchors.left,
    minZoom: 2,
    maxZoom: 7,
  );
  if (camera == null) throw StateError('Story camera fit unavailable');
  return camera;
}
