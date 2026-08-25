import 'dart:async';
import 'dart:math' show Point;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/map_trace.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

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
    this.onMapIdle,
    this.onCameraIdle,
    this.onCameraMove,
    this.interactive = true,
    this.compassEnabled = true,
    this.showUserLocation = true,
    this.includeTerrainInStyle = true,
    this.minZoomPreference = defaultMinZoom,
    this.maxZoomPreference = maxZoom,
    this.tabIndex,
    this.recreateOnReturn = false,
    this.onMapInvalidated,
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

  /// Deep-zoom ceiling for most surfaces. Was 11, which users kept hitting
  /// as "the map goes blurry and then just stops" — vector basemap re-renders
  /// crisply far past this, and raster sources now carry their own caps.
  static const double maxZoom = 16;

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  /// Called on a map tap with the tapped point + coordinate — for tap-driven
  /// layers (e.g. selecting the nearest weather station).
  final OnMapClickCallback? onMapClick;

  /// Fires when MapLibre's native renderer has fully loaded the visible
  /// sources and has no pending repaint. Unlike [onCameraIdle], this also
  /// covers source/tile changes made while the camera stays still.
  final OnMapIdleCallback? onMapIdle;

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

  /// Whether the initial native style contains the terrain DEM and hillshade.
  /// Runtime owners can still add terrain later. Omitting it here prevents an
  /// OSM-first surface from fetching and briefly painting an unused DEM.
  final bool includeTerrainInStyle;

  /// Per-surface zoom floor (typhoon may go lower so the whole basin fits).
  /// Other layers keep [defaultMinZoom].
  final double minZoomPreference;

  /// Per-surface zoom ceiling (DPM AED may go to 16).
  final double maxZoomPreference;

  /// Shell tab that owns this surface, if any. Its native render loop pauses
  /// while that retained `IndexedStack` branch is hidden and resumes when the
  /// branch becomes visible again.
  /// `null` belongs to no branch (a full-screen route or external preview).
  final int? tabIndex;

  /// Recreates the iOS platform view if its native resume cannot render a frame.
  ///
  /// Flutter keeps an `IndexedStack` branch (and therefore its `UiKitView`)
  /// mounted while another tab is selected. The plugin first resumes the same
  /// MLNMapView and completes only after `didFinishRenderingFrame`; a timeout
  /// reaches this fallback. Rebuilding the surrounding Flutter widget is
  /// insufficient because it preserves the same platform view, so changing the
  /// map key gives UIKit a fresh native view.
  ///
  /// This is opt-in because a display-only backdrop or a full-screen map route
  /// does not have the retained-tab failure mode. Android and a healthy iOS map
  /// keep their cheaper pause/resume path regardless of this value.
  final bool recreateOnReturn;

  /// Called immediately before [recreateOnReturn] discards a live controller.
  /// The owner must forget all style-bound state and stop sending operations to
  /// that controller; [onMapCreated] then supplies its replacement.
  final void Function(MapLibreMapController controller)? onMapInvalidated;

  @override
  State<BaseMap> createState() => _BaseMapState();
}

class _BaseMapState extends State<BaseMap> with WidgetsBindingObserver {
  final int _traceId = nextMapTraceId();

  String get _traceScope => 'base#$_traceId/tab=${widget.tabIndex}';

  void _trace(String Function() message) => mapTrace(_traceScope, message);

  /// Set once the platform view reports in — the readiness gate for the retry.
  MapLibreMapController? _controller;

  /// The shell's visible-tab notifier ([VisibleTabScope.of] may be null when
  /// this surface lives outside the shell — then it never pauses).
  VisibleTab? _visibleTab;

  /// Last-applied pause state, so [setRenderPaused] fires only on transitions.
  bool _renderPaused = false;

  /// Whether the app itself is in the foreground. Used by platforms whose
  /// native render lifecycle is safe to drive from Dart.
  bool _foreground = true;

  /// Last effective visibility, including both shell and app lifecycle. This
  /// lets the native-view workaround run once on a hidden -> visible edge.
  bool _wasOnScreen = true;

  /// Bumped to remount the map's platform view after a failed first attempt
  /// (see [_scheduleReadinessRetry]).
  int _mountAttempt = 0;
  int _readinessRetries = 0;

  Timer? _readinessTimer;

  @override
  void initState() {
    super.initState();
    _trace(() => 'init platform=$defaultTargetPlatform');
    WidgetsBinding.instance.addObserver(this);
    _scheduleReadinessRetry();
  }

  /// A backgrounded app still owns its platform views, and MapLibre draws from
  /// its own native render loop rather than Flutter's — so the engine going
  /// quiet does not stop it. Pause it explicitly where the native lifecycle is
  /// safe to control from Dart; iOS MapLibre observes app backgrounding itself.
  ///
  /// `inactive` is left running on purpose: it fires for a transient overlay
  /// (the notification shade, the app switcher preview) where the map is still
  /// on screen and a paused surface would be visibly frozen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = switch (state) {
      AppLifecycleState.paused ||
      AppLifecycleState.hidden ||
      AppLifecycleState.detached => false,
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    };
    _trace(() => 'app-lifecycle state=$state foreground=$foreground');
    if (foreground == _foreground) return;
    _foreground = foreground;
    _syncVisibility(trigger: 'app-lifecycle');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visibleTab = VisibleTabScope.of(context);
    if (identical(visibleTab, _visibleTab)) return;
    _visibleTab?.removeListener(_onTabChanged);
    _visibleTab = visibleTab;
    visibleTab?.addListener(_onTabChanged);
    _trace(
      () =>
          'visible-scope attached scope=${mapTraceObject(visibleTab)} '
          'selected=${visibleTab?.value} shellOnTop=${visibleTab?.shellOnTop}',
    );
    _wasOnScreen = _isOnScreen;
    _syncRender();
  }

  @override
  void didUpdateWidget(BaseMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _trace(
      () =>
          'widget-update tab=${oldWidget.tabIndex}->${widget.tabIndex} '
          'interactive=${oldWidget.interactive}->${widget.interactive}',
    );
  }

  @override
  void reassemble() {
    _trace(
      () => 'hot-reload reassemble controller=${mapTraceObject(_controller)}',
    );
    super.reassemble();
  }

  @override
  void dispose() {
    _trace(() => 'dispose controller=${mapTraceObject(_controller)}');
    _visibleTab?.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    _readinessTimer?.cancel();
    super.dispose();
  }

  /// A surface is worth drawing only while the app is in the foreground *and*
  /// the surface is in front of the user — its branch selected and nothing
  /// pushed over the shell ([VisibleTab.isOnScreen]). No scope at all means the
  /// map lives outside the shell (a full-screen route, a preview), where the
  /// only thing that can hide it is the app leaving the foreground.
  ///
  /// The controller may not exist yet — the state is kept and applied when the
  /// platform view reports in ([_onMapCreated]), so `_renderPaused` only records
  /// states that actually reached the platform.
  void _syncRender() {
    final onScreen = _visibleTab?.isOnScreen(widget.tabIndex) ?? true;
    final pause = !(_foreground && onScreen);
    final controller = _controller;
    _trace(
      () =>
          'render-sync selected=${_visibleTab?.value} '
          'shellOnTop=${_visibleTab?.shellOnTop} onScreen=$onScreen '
          'foreground=$_foreground '
          'desiredPause=$pause appliedPause=$_renderPaused '
          'controller=${mapTraceObject(controller)}',
    );
    if (controller == null || pause == _renderPaused) return;
    _renderPaused = pause;
    final started = Stopwatch()..start();
    unawaited(
      controller
          .setRenderPaused(pause)
          .then(
            (_) => _trace(
              () =>
                  'render-sync native-complete pause=$pause '
                  'dt=${started.elapsedMilliseconds}ms',
            ),
          )
          .catchError((Object error, StackTrace stackTrace) {
            _trace(
              () =>
                  'render-sync native-error pause=$pause '
                  'dt=${started.elapsedMilliseconds}ms error=$error',
            );
            Log.handle(error, stackTrace, 'map render pause');
            if (!pause &&
                mounted &&
                identical(controller, _controller) &&
                _isOnScreen &&
                widget.recreateOnReturn &&
                defaultTargetPlatform == TargetPlatform.iOS) {
              _trace(() => 'native-resume failed; recreating native view');
              _recreateNativeView(trigger: 'native-resume-failed');
            }
          }),
    );
  }

  void _onTabChanged() {
    _trace(
      () =>
          'visible-notify selected=${_visibleTab?.value} '
          'shellOnTop=${_visibleTab?.shellOnTop}',
    );
    _syncVisibility(trigger: 'shell');
  }

  bool get _isOnScreen =>
      _foreground && (_visibleTab?.isOnScreen(widget.tabIndex) ?? true);

  /// Applies the ordinary render lifecycle. A failed verified iOS resume falls
  /// back to [_recreateNativeView] from [_syncRender].
  void _syncVisibility({required String trigger}) {
    final onScreen = _isOnScreen;
    final returned = onScreen && !_wasOnScreen;
    _wasOnScreen = onScreen;
    _trace(() => 'visibility-sync trigger=$trigger returned=$returned');
    _syncRender();
  }

  void _recreateNativeView({required String trigger}) {
    final controller = _controller;
    if (controller == null) return;
    _trace(
      () =>
          'native-recreate start trigger=$trigger '
          'attempt=${_mountAttempt + 1} controller=${mapTraceObject(controller)}',
    );
    widget.onMapInvalidated?.call(controller);
    _controller = null;
    _renderPaused = false;
    _readinessRetries = 0;
    _readinessTimer?.cancel();
    setState(() => _mountAttempt++);
    _scheduleReadinessRetry();
  }

  /// Forwards map readiness to the caller and stops the retry timer.
  void _onMapCreated(int mountAttempt, MapLibreMapController controller) {
    if (mountAttempt != _mountAttempt) {
      _trace(
        () =>
            'map-created stale attempt=$mountAttempt current=$_mountAttempt '
            'controller=${mapTraceObject(controller)}',
      );
      return;
    }
    _controller = controller;
    _readinessRetries = 0;
    _trace(() => 'map-created controller=${mapTraceObject(controller)}');
    _readinessTimer?.cancel();
    // A remount (retry) may have superseded this element — never hand a stale
    // controller, whose native view is being torn down, to the caller.
    if (!mounted) return;
    _syncRender();
    widget.onMapCreated?.call(controller);
  }

  void _onStyleLoaded(int mountAttempt) {
    if (mountAttempt != _mountAttempt) {
      _trace(
        () => 'style-loaded stale attempt=$mountAttempt current=$_mountAttempt',
      );
      return;
    }
    _trace(() => 'style-loaded controller=${mapTraceObject(_controller)}');
    widget.onStyleLoaded?.call();
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
      if (_readinessRetries < 2) {
        _readinessRetries++;
        _trace(
          () =>
              'readiness-timeout retry=$_readinessRetries '
              'remount=${_mountAttempt + 1}',
        );
        setState(() => _mountAttempt++);
        _scheduleReadinessRetry();
        return;
      }
      _trace(() => 'readiness-failed retries=$_readinessRetries');
      Log.warning('Map platform view never became ready after remounts');
    });
  }

  /// Style string memoised per palette — all other inputs are const, and
  /// Every [build] used to re-interpolate the full style JSON — the string only
  /// varies by palette, town-label directory, and terrain presence, so it is
  /// memoised on that tuple.
  static final Map<(MapPalette, String, bool), String> _styleCache = {};

  static String _styleString(
    MapPalette palette,
    String townLabelData,
    bool includeTerrain,
  ) => _styleCache.putIfAbsent(
    (palette, townLabelData, includeTerrain),
    () => exptechVectorStyle(
      palette,
      basemapTileUrl: basemapOriginTileUrl,
      glyphsUrl: glyphsOriginUrl,
      terrainTileUrl: includeTerrain ? terrainOriginTileUrl : null,
      townLabelData: townLabelData,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final mountAttempt = _mountAttempt;
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
      // The interpolated string only varies by palette and the town directory,
      // so it is memoised — every rebuild used to re-run the ~2 KB
      // interpolation and the per-town GeoJSON stringification. Township-name
      // labels come from the app's own directory (a unique GeoJSON point per
      // township), never the tile polygons — see [townLabelGeoJson].
      styleString: _styleString(
        palette,
        townLabelGeoJson(context.read<TownDirectory>()),
        widget.includeTerrainInStyle,
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
      onMapClick: widget.onMapClick == null
          ? null
          : (point, coordinate) {
              if (mountAttempt == _mountAttempt) {
                widget.onMapClick?.call(point, coordinate);
              }
            },
      onMapCreated: (controller) => _onMapCreated(mountAttempt, controller),
      onStyleLoadedCallback: () => _onStyleLoaded(mountAttempt),
      onMapIdle: widget.onMapIdle == null
          ? null
          : () {
              if (mountAttempt == _mountAttempt) {
                widget.onMapIdle?.call();
              }
            },
      onCameraMove: widget.onCameraMove == null
          ? null
          : (position) {
              if (mountAttempt == _mountAttempt) {
                widget.onCameraMove?.call(position);
              }
            },
      onCameraIdle: widget.onCameraIdle == null
          ? null
          : () {
              if (mountAttempt == _mountAttempt) {
                widget.onCameraIdle?.call();
              }
            },
    );
  }
}
