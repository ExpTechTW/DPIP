import 'dart:async';
import 'dart:math' show Point;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Layer-chip band under the safe-area top: outer pad ([AppSpacing.lg]) + chip
/// height (~36) + a tight gap. iOS MapLibre already anchors ornaments to the
/// safe top, so this is the full Y margin there; Android still needs safe-area
/// padding added on top (see [BaseMap.build]). MapScaffold reuses it to park its
/// Flutter [MapCompass] in the same spot the native compass occupied.
const double layerChipBand = AppSpacing.lg + 36 + AppSpacing.xs;

/// The app's reusable base map — a MapLibre map centred on Taiwan, rendered from
/// the ExpTech vector style tinted by [MapColors] for the active brightness.
///
/// This is the shared foundation every map surface builds on (home backdrop,
/// map tab, radar preview, event viewers). It is layer-agnostic: callers add
/// their own sources/layers in [onMapCreated] via the [MapLibreMapController],
/// typically anchoring overlays below [outlineLayerId] so the borders stay on
/// top.
///
/// [interactive] toggles pan/zoom/rotate and the compass at once — pass
/// `false` for a display-only surface like the home backdrop, where the map is
/// driven entirely from code and the page's own gestures (tap to open, swipe
/// to switch) must pass straight through. Tilt is always off.
///
/// The map is [StatefulWidget] so it can self-heal a failed platform-view
/// mount: after an iOS hot restart the engine can still own the previous
/// run's view id, the framework re-issues it, and `UiKitView` creation fails
/// with `recreating_view` — the map remounts with a fresh id and recovers
/// (see [_BaseMapState]).
class BaseMap extends StatefulWidget {
  const BaseMap({
    super.key,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onMapClick,
    this.onCameraIdle,
    this.onCameraMove,
    this.interactive = true,
    this.compassEnabled = true,
    this.showUserLocation = true,
    this.minZoomPreference = defaultMinZoom,
    this.maxZoomPreference = maxZoom,
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

  /// Default floor for most map surfaces (radar tiles need it).
  static const double defaultMinZoom = 4;

  /// Alias for call sites / framing that still reference [BaseMap.minZoom].
  static const double minZoom = defaultMinZoom;

  static const double maxZoom = 11;

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  /// Called on a map tap with the tapped point + coordinate — for tap-driven
  /// layers (e.g. selecting the nearest weather station).
  final OnMapClickCallback? onMapClick;

  /// Fires when the camera stops moving — for screen-space Flutter overlays
  /// that need a fresh `toScreenLocation` projection.
  final OnCameraIdleCallback? onCameraIdle;

  /// Fires on every camera move with the new position — [MapCompass] uses the
  /// bearing so the needle tracks rotation live.
  final OnCameraMoveCallback? onCameraMove;

  /// Whether the user can pan/zoom/rotate the map. `false` makes it display-only
  /// (all gestures + the compass off) so the surrounding page owns every gesture.
  final bool interactive;

  /// Whether the **native** MapLibre compass shows (when [interactive]).
  ///
  /// The native compass lives inside the platform view, so any Flutter overlay
  /// paints over it. MapScaffold turns it off and draws its own [MapCompass]
  /// at the top of the chrome stack instead, keeping north reachable even under
  /// screen-space callouts (typhoon forecast tips).
  final bool compassEnabled;

  /// Whether to draw the device-location puck.
  ///
  /// This is MapLibre's **native** location component — `MLNUserLocationAnnot‌‍
  /// ationView` on iOS, `LocationComponent` on Android — so the blue dot,
  /// accuracy ring and heading cone are rendered and animated on the render
  /// thread, with no per-frame platform-channel traffic. It runs the platform's
  /// own location + heading session and starts only once location permission is
  /// granted (Android logs and skips otherwise); nothing is drawn when it is
  /// denied. Styling is whatever the platform provides — the plugin exposes no
  /// hook for colours.
  final bool showUserLocation;

  /// Per-surface zoom floor (typhoon may go lower so the whole basin fits).
  /// Other layers keep [defaultMinZoom].
  final double minZoomPreference;

  /// Per-surface zoom ceiling (DPM AED may go to 16).
  final double maxZoomPreference;

  @override
  State<BaseMap> createState() => _BaseMapState();
}

class _BaseMapState extends State<BaseMap> {
  /// Set once the platform view reports in — the readiness gate for the retry.
  MapLibreMapController? _controller;

  /// Bumped to remount the map's platform view after a failed first attempt
  /// (see [_scheduleReadinessRetry]).
  int _mountAttempt = 0;

  Timer? _readinessTimer;

  @override
  void initState() {
    super.initState();
    _scheduleReadinessRetry();
  }

  @override
  void dispose() {
    _readinessTimer?.cancel();
    super.dispose();
  }

  /// Forwards map readiness to the caller and stops the retry timer.
  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    _readinessTimer?.cancel();
    // A remount (retry) may have superseded this element — never hand a stale
    // controller, whose native view is being torn down, to the caller.
    if (!mounted) return;
    widget.onMapCreated?.call(controller);
  }

  /// The engine doesn't tear down iOS platform views synchronously across a
  /// hot restart, so a fresh isolate can collide with the previous run's view
  /// (the framework re-issues id 0 while the engine still owns it) and the
  /// map's UiKitView creation fails with `recreating_view` — [onMapCreated]
  /// never fires and the surface would sit blank for the session. Remount with
  /// a fresh key: the new attempt allocates a new platform-view id and
  /// succeeds. Bounded — two remounts clears any async teardown, and a
  /// persistent failure is a real problem that should surface, not loop.
  void _scheduleReadinessRetry() {
    _readinessTimer?.cancel();
    _readinessTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _controller != null) return;
      if (_mountAttempt < 2) {
        setState(() => _mountAttempt++);
        _scheduleReadinessRetry();
        return;
      }
      Log.warning('Map platform view never became ready after remounts');
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = MapColors.of(Theme.of(context).brightness);
    // MapScaffold parks the layer switcher at top-right (SafeArea + lg). Drop
    // the native compass just under that chip. iOS ornaments are already
    // constrained to the safe-area top — adding MediaQuery.padding again left
    // a huge gap under the chip. Android margins are from the view edge.
    final safeTop = Theme.of(context).platform == TargetPlatform.iOS
        ? 0.0
        : MediaQuery.paddingOf(context).top;
    final compassTop = safeTop + layerChipBand;
    final floor = widget.minZoomPreference;
    final ceiling = widget.maxZoomPreference;
    return MapLibreMap(
      // Pre-layout placeholder only; each surface fits [taiwanBounds] (or its
      // own selection) once the map is laid out, so no hardcoded framing zoom.
      initialCameraPosition: CameraPosition(
        target: BaseMap.taiwanCenter,
        zoom: floor,
      ),
      // Brightness flip / AED overlay changes this string → MapLibre reloads
      // style; layers re-attach via [onStyleLoaded] (see [MapScaffold]).
      styleString: exptechVectorStyle(
        palette,
        basemapTileUrl: basemapOriginTileUrl,
        glyphsUrl: glyphsOriginUrl,
        terrainTileUrl: terrainOriginTileUrl,
      ),
      // A remount gets a fresh id, so a collided first attempt recovers (see
      // [_scheduleReadinessRetry]).
      key: ValueKey(_mountAttempt),
      minMaxZoomPreference: MinMaxZoomPreference(floor, ceiling),
      trackCameraPosition: true,
      compassEnabled: widget.interactive && widget.compassEnabled,
      compassViewPosition: CompassViewPosition.topRight,
      compassViewMargins: Point(AppSpacing.lg, compassTop),
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: false,
      dragEnabled: widget.interactive,
      myLocationEnabled: widget.showUserLocation,
      // `compass` is the heading-cone mode; MapLibreMap asserts anything other
      // than `normal` requires myLocationEnabled, so pair them.
      myLocationRenderMode: widget.showUserLocation
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      onMapClick: widget.onMapClick,
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: widget.onStyleLoaded,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
    );
  }
}
