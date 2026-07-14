import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The app's reusable base map — a MapLibre map centred on Taiwan, rendered from
/// the theme-driven ExpTech vector style (same base as the home snapshot).
///
/// This is the shared foundation every map surface builds on (home backdrop,
/// map tab, radar preview, event viewers). It is layer-agnostic: callers add
/// their own sources/layers in [onMapCreated] via the [MapLibreMapController],
/// typically anchoring overlays below [outlineLayerId] so the borders stay on
/// top.
///
/// [interactive] toggles every user gesture (pan/zoom/rotate/tilt) and the
/// compass at once — pass `false` for a display-only surface like the home
/// backdrop, where the map is driven entirely from code and the page's own
/// gestures (tap to open, swipe to switch) must pass straight through.
class BaseMap extends StatelessWidget {
  const BaseMap({
    super.key,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onMapClick,
    this.interactive = true,
  });

  /// Bounding box framing the Taiwan main island — the single source of the
  /// nationwide framing, fit to the viewport (never a hardcoded zoom). Kept to
  /// the main island (no Penghu/Kinmen/Matsu) so it isn't dominated by open sea.
  static final LatLngBounds taiwanBounds = LatLngBounds(
    southwest: const LatLng(22.2, 119),
    northeast: const LatLng(25.35, 121.05),
  );

  /// Centre of [taiwanBounds] — only the pre-layout camera target, before a
  /// fit-to-bounds frames the island properly. Derived, so it can't drift from
  /// the bounds.
  static LatLng get taiwanCenter => LatLng(
    (taiwanBounds.southwest.latitude + taiwanBounds.northeast.latitude) / 2,
    (taiwanBounds.southwest.longitude + taiwanBounds.northeast.longitude) / 2,
  );

  /// Fixed 4–11 zoom range — the radar echo tiles require it.
  static const double minZoom = 4;
  static const double maxZoom = 11;
  static const MinMaxZoomPreference zoomRange = MinMaxZoomPreference(
    minZoom,
    maxZoom,
  );

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  /// Called on a map tap with the tapped point + coordinate — for tap-driven
  /// layers (e.g. selecting the nearest weather station).
  final OnMapClickCallback? onMapClick;

  /// Whether the user can pan/zoom/rotate the map. `false` makes it display-only
  /// (all gestures + the compass off) so the surrounding page owns every gesture.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MapLibreMap(
      // Pre-layout placeholder only; each surface fits [taiwanBounds] (or its
      // own selection) once the map is laid out, so no hardcoded framing zoom.
      initialCameraPosition: CameraPosition(
        target: taiwanCenter,
        zoom: minZoom,
      ),
      styleString: exptechVectorStyle(
        sea: colors.surface.toHexRgb(),
        land: colors.surfaceContainer.toHexRgb(),
        countyTown: colors.surfaceContainerHigh.toHexRgb(),
        outline: colors.outline.toHexRgb(),
        townOutline: colors.outlineVariant.toHexRgb(),
      ),
      minMaxZoomPreference: zoomRange,
      trackCameraPosition: true,
      compassEnabled: interactive,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      dragEnabled: interactive,
      onMapClick: onMapClick,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
    );
  }
}
