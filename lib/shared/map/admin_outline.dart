import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
import 'package:maplibre_gl/maplibre_gl.dart';

/// An administrative boundary set that can be redrawn over a weather raster.
enum AdminBoundary {
  /// 國界 — the world's country borders. The outermost frame; drawn only when
  /// explicitly asked for, because on a Taiwan-focused surface the neighbours'
  /// outlines are usually noise.
  global(
    sourceLayer: 'global',
    casingLayerId: 'admin-global-outline-casing',
    lineLayerId: 'admin-global-outline',
    casingWidth: 2.8,
    casingOpacity: 0.4,
    lineWidth: 1.1,
    lineOpacity: 0.9,
  ),

  /// 縣市 — the coarse frame. Heavier, because it is the one people navigate by.
  county(
    sourceLayer: 'city',
    casingLayerId: 'admin-county-outline-casing',
    lineLayerId: 'admin-county-outline',
    casingWidth: 3.0,
    casingOpacity: 0.45,
    lineWidth: 1.2,
    lineOpacity: 0.95,
  ),

  /// 鄉鎮 — the fine mesh. Deliberately lighter: at 368 townships a stroke as
  /// strong as the county one turns the island into a net and buries the echo
  /// it is meant to sit over.
  town(
    sourceLayer: 'town',
    casingLayerId: 'admin-town-outline-casing',
    lineLayerId: 'admin-town-outline',
    casingWidth: 1.8,
    casingOpacity: 0.3,
    lineWidth: 0.7,
    lineOpacity: 0.7,
  );

  const AdminBoundary({
    required this.sourceLayer,
    required this.casingLayerId,
    required this.lineLayerId,
    required this.casingWidth,
    required this.casingOpacity,
    required this.lineWidth,
    required this.lineOpacity,
  });

  /// The vector tile layer in the base style's source.
  final String sourceLayer;

  final String casingLayerId;
  final String lineLayerId;
  final double casingWidth;
  final double casingOpacity;
  final double lineWidth;
  final double lineOpacity;
}

/// Administrative borders drawn **over** a weather raster.
///
/// The base style outlines counties and townships, but a full-saturation raster
/// covers them: radar sits above those borders precisely so the echo is not
/// interrupted, which leaves the map unreadable exactly where the weather is
/// worth looking at. This puts a second, louder set back on top — and because
/// it is a separate layer it can be switched off to get the clean raster back.
///
/// Each set is drawn as a **casing**: a wide dark line under a narrow light one.
/// That is the standard cartographic answer to "must be legible over anything" —
/// the dark edge separates the border from bright echo, the light core separates
/// it from dark echo, and neither depends on knowing what is underneath.
abstract final class AdminOutline {
  AdminOutline._();

  /// The vector source the base style already declares.
  static const String sourceId = 'exptech';

  /// Wide dark under-stroke, so a border reads against pale echo.
  static const String casingColor = '#000000';

  /// Narrow light core, so it reads against dark echo and the basemap.
  static const String lineColor = '#FFFFFF';

  /// Adds [boundary]'s two strokes. Casing first so the core paints over it.
  ///
  /// [lineColor] overrides the default light core — the typhoon surface's
  /// satellite underlay passes bright yellow there, because on fully-opaque
  /// imagery the default white does not survive. [belowLayerId] defaults to
  /// under the township-name labels — a border line must never cross a place
  /// name, so the labels stay the top-most text on every surface; the typhoon
  /// surface passes an explicit anchor instead when its own overlays must not
  /// be crossed by a line.
  static Future<void> add(
    MapLibreMapController controller,
    AdminBoundary boundary, {
    String lineColor = AdminOutline.lineColor,
    String? belowLayerId = townLabelLayerId,
  }) async {
    await controller.addLineLayer(
      sourceId,
      boundary.casingLayerId,
      LineLayerProperties(
        lineColor: casingColor,
        lineWidth: boundary.casingWidth,
        lineOpacity: boundary.casingOpacity,
        lineJoin: 'round',
        lineCap: 'round',
      ),
      sourceLayer: boundary.sourceLayer,
      belowLayerId: belowLayerId,
      enableInteraction: false,
    );
    await controller.addLineLayer(
      sourceId,
      boundary.lineLayerId,
      LineLayerProperties(
        lineColor: lineColor,
        lineWidth: boundary.lineWidth,
        lineOpacity: boundary.lineOpacity,
        lineJoin: 'round',
        lineCap: 'round',
      ),
      sourceLayer: boundary.sourceLayer,
      belowLayerId: belowLayerId,
      enableInteraction: false,
    );
  }

  /// Removes [boundary]'s strokes, tolerating a partially-added state.
  ///
  /// Never touches [sourceId] — it belongs to the base style, and removing it
  /// would wipe the map.
  static Future<void> remove(
    MapLibreMapController controller,
    AdminBoundary boundary,
  ) async {
    for (final id in [boundary.lineLayerId, boundary.casingLayerId]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {
        // Not present — nothing to undo.
      }
    }
  }
}
