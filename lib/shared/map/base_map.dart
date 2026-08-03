import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The app's reusable base map — a MapLibre map centred on Taiwan, rendered from
/// the ExpTech vector style tinted by [MapColors] for the active brightness.
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

  /// Bounding box for the nationwide (全國) framing — the Taiwan main island
  /// **plus Kinmen**, fit to the viewport (never a hardcoded zoom). Penghu falls
  /// inside the span already; Matsu does not (it sits at ~26.15°N, north of the
  /// box) — add it here if it should be framed too.
  ///
  /// The corners are the real extremes, with a little margin: Fugui Cape
  /// 25.30°N, Eluanbi 21.90°N, Sandiao Cape 122.01°E, and Lieyu (Little Kinmen)
  /// ~118.20°E.
  ///
  /// An earlier box read `(22.2, 119) → (25.35, 121.05)`: it reached ~110 km into
  /// the strait on the west yet stopped at 121.05°E — *inside* the island — so
  /// the whole east coast (Yilan / Hualien / Taitung) fell outside the box and the
  /// fit centred on 120.02°E, pushing Taiwan against the right edge with open sea
  /// filling the left.
  ///
  /// A getter, not a `static final`: a lazily-initialised static keeps its first
  /// value across hot reload, so editing these numbers would appear to do nothing.
  static LatLngBounds get taiwanBounds => LatLngBounds(
    southwest: const LatLng(21.87, 118.15),
    northeast: const LatLng(25.32, 122.05),
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
    final palette = MapColors.of(Theme.of(context).brightness);
    return MapLibreMap(
      // Pre-layout placeholder only; each surface fits [taiwanBounds] (or its
      // own selection) once the map is laid out, so no hardcoded framing zoom.
      initialCameraPosition: CameraPosition(
        target: taiwanCenter,
        zoom: minZoom,
      ),
      // Brightness flip changes this string → MapLibre reloads style; layers
      // re-attach via [onStyleLoaded] (see [MapScaffold]).
      styleString: exptechVectorStyle(palette),
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
