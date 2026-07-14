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
    this.interactive = true,
    this.maxZoom = 11,
  });

  /// Centre of Taiwan.
  static const LatLng taiwanCenter = LatLng(23.60, 120.85);

  /// Default zoom framing the whole island.
  static const double taiwanZoom = 6.4;

  /// Bounding box framing the main island (plus Penghu) — for the nationwide
  /// fit-to-bounds framing on the home backdrop.
  static final LatLngBounds taiwanBounds = LatLngBounds(
    southwest: const LatLng(21.85, 119.35),
    northeast: const LatLng(25.40, 122.05),
  );

  /// Lowest zoom the map will show — the radar echo tiles start here.
  static const double minZoom = 4;

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  /// Whether the user can pan/zoom/rotate the map. `false` makes it display-only
  /// (all gestures + the compass off) so the surrounding page owns every gesture.
  final bool interactive;

  /// Highest zoom the map will show — also the tightest a fit-to-bounds framing
  /// zooms in. Defaults to 11, the ceiling the radar echo tiles exist at; a
  /// display surface can lower it to frame selections looser.
  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MapLibreMap(
      initialCameraPosition: const CameraPosition(
        target: taiwanCenter,
        zoom: taiwanZoom,
      ),
      styleString: exptechVectorStyle(
        sea: colors.surface.toHexRgb(),
        land: colors.surfaceContainer.toHexRgb(),
        countyTown: colors.surfaceContainerHigh.toHexRgb(),
        outline: colors.outline.toHexRgb(),
        townOutline: colors.outlineVariant.toHexRgb(),
      ),
      minMaxZoomPreference: MinMaxZoomPreference(minZoom, maxZoom),
      trackCameraPosition: true,
      compassEnabled: interactive,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      dragEnabled: interactive,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
    );
  }
}
