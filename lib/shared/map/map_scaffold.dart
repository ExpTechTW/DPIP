import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/map_cache.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_interaction_tracker.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:dpip/shared/map/map_compass.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart'
    show VisibleTab, VisibleTabScope;
import 'package:dpip/shared/widgets/collapsible_map_legend.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// Basemap XYZ origin — warmed from the app's tile store into MapLibre's tile
/// memory on camera idle. LB has no ETag; the store keys these by URL hash.
const String _basemapTileUrl = basemapOriginTileUrl;

/// The runtime DEM source — identical to what the baked style declares (see
/// [exptechVectorStyle]), so [MapScaffold] can rebuild the relief after
/// removing it, with no drift between the two descriptions.
const RasterDemSourceProperties _terrainSourceProps = RasterDemSourceProperties(
  tiles: [terrainOriginTileUrl],
  bounds: [110.0, 10.0, 132.0, 35.0],
  minzoom: 0,
  maxzoom: 12,
  tileSize: 512,
  encoding: 'mapbox',
);

/// The runtime hillshade layer — same id, same paint as the baked style.
const HillshadeLayerProperties _terrainLayerProps = HillshadeLayerProperties(
  hillshadeIlluminationDirection: terrainIlluminationDirection,
  hillshadeExaggeration: terrainExaggeration,
);

/// The reusable map surface — a base map with a switchable, time-scrubbable
/// overlay layer.
///
/// This owns everything map pages used to repeat: the MapLibre controller
/// lifecycle, which [MapLayer] is active (the layer switcher), and which frame
/// is shown (the timeline). A page just hands it the layers it offers and stays
/// focused on assembling those — every layer plugs into the same controls.
///
/// Layer/frame changes are serialised onto one queue so MapLibre add/remove
/// calls never overlap, and a generation counter drops results from a superseded
/// layer load so a slow fetch can't render onto the wrong layer.
class MapScaffold extends StatefulWidget {
  const MapScaffold({
    super.key,
    required this.layers,
    this.initialLayerId,
    this.tabIndex,
  }) : assert(layers.length > 0, 'MapScaffold needs at least one layer');

  /// The layers this surface offers; [initialLayerId] (or the first entry) is
  /// shown initially.
  final List<MapLayer> layers;

  /// Preferred overlay id (`MapLayer.id`) when the surface mounts. Unknown /
  /// missing → [layers].first.
  final String? initialLayerId;

  /// Shell tab owning this surface — forwarded to [BaseMap] so the map pauses
  /// its native render loop while the tab is hidden. `null` never pauses.
  final int? tabIndex;

  @override
  State<MapScaffold> createState() => _MapScaffoldState();
}

class _MapScaffoldState extends State<MapScaffold> with WidgetsBindingObserver {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  late final MapInteractionTracker _mapInteraction;
  Future<void> _tileCacheReady = Future<void>.value();

  /// The shell's visible-tab notifier — same contract as [BaseMap]: null
  /// (full-screen routes, previews) means always visible.
  VisibleTab? _visibleTab;

  /// Whether the initial framing has run. Only on first load — a reload (theme
  /// change) keeps whatever the user has panned/zoomed to.
  bool _framed = false;

  /// Hand-off of a target framing from whoever opened the map (the Home backdrop
  /// tap, or the nav bar). A one-shot request per open; null keeps the view.
  MapCameraHandoff? _handoff;

  /// Ranking → map: switch layer, frame station, open sheet.
  MapStationHandoff? _stationHandoff;

  late MapLayer _active = _resolveInitial(widget);

  static MapLayer _resolveInitial(MapScaffold widget) {
    final id = widget.initialLayerId;
    if (id != null) {
      for (final layer in widget.layers) {
        if (layer.id == id) return layer;
      }
    }
    return widget.layers.first;
  }

  List<MapFrame> _frames = const [];
  int _selectedIndex = 0;
  Failure? _error;

  /// Bumped on every layer load; a load whose generation is stale is discarded.
  int _generation = 0;

  /// Serialises controller mutations so an add never races a remove.
  Future<void> _mapOps = Future<void>.value();

  /// Bumped on camera idle so screen-space [MapLayer.buildMapOverlay] reprojects.
  /// A [ValueNotifier], not a `setState` bump: only the overlay subtree (which
  /// keys off it) rebuilds, instead of the whole scaffold — every pan/zoom
  /// settle used to rebuild the platform view, chrome and legend too.
  final ValueNotifier<int> _cameraEpoch = ValueNotifier(0);

  /// Basemap tile warm-up. Its own warmer so a layer's cancel can't abort it.
  MapTileWarmer? _basemapWarmer;

  /// Whether a frame-show op is already queued and hasn't started running yet.
  ///
  /// Timeline reports every crossed frame; settle mounts (~3 sources) are the
  /// expensive path. Coalesce so at most one op waits behind the running one.
  bool _showQueued = false;

  /// Finger down / fling in flight — raster layers skip cold mounts.
  bool _scrubbing = false;

  /// Turns on only when timeline samples outrun the bounded map-operation
  /// queue. It is a notifier so the warning can appear without rebuilding the
  /// platform-view map underneath it.
  final TimelineScrubBackpressure _scrubBackpressure =
      TimelineScrubBackpressure();

  /// The map view's own size, captured at layout — see [_applyFraming].
  Size? _mapViewSize;

  /// Current camera heading — drives the Flutter compass needle. A notifier so
  /// only the compass rebuilds while the map rotates.
  final ValueNotifier<double> _bearing = ValueNotifier(0);

  /// Whether the base map's township-name labels are shown. A base-map
  /// property, not a layer's, so it lives here (shared by every layer's menu)
  /// instead of on one chrome mixin. Defaults on, per the layer docs.
  final ValueNotifier<bool> _showTownLabels = ValueNotifier(true);

  /// Whether the base map's terrain-relief (hillshade) is shown. Also a
  /// base-map property, so it lives beside [_showTownLabels]. Defaults on —
  /// the relief is the terrain feature's whole point.
  final ValueNotifier<bool> _showTerrain = ValueNotifier(true);

  /// Whether the terrain source + hillshade layer are actually on the map.
  ///
  /// This mirrors the native state so the toggle can add/remove instead of
  /// flipping visibility (see [_syncTerrain]). A style reload re-bakes both,
  /// so [_onStyleLoaded] sets it back to true and re-syncs.
  bool _terrainOnMap = false;

  /// The geography the map is framed on, kept across layer switches so each
  /// layer re-frames the *same* place into its own visible band.
  LatLngBounds? _target;

  /// Measured height of the timeline panel (0 when the active layer has none).
  double _timelineHeight = 0;
  final GlobalKey _timelineKey = GlobalKey();

  /// A deliberate framing ([_frameBounds] — a nav-bar / Home entry, the first
  /// load, a station focus) ran while the timeline's height was still zero —
  /// switching into a timeline layer zeroes it and the fit placed the subject
  /// behind the scrubber. Set by [_frameBounds], cleared once the measured
  /// height re-fits the camera, and never set by a bare layer switch (which
  /// must not move the camera at all).
  bool _reframeOnMeasure = false;

  @override
  void initState() {
    super.initState();
    _mapInteraction = MapInteractionTracker(
      onStart: () => _active.onMapGestureStart(),
      onEnd: () => _active.onMapGestureEnd(),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handoff = context.read<MapCameraHandoff>();
    if (handoff != _handoff) {
      _handoff?.removeListener(_onHandoff);
      _handoff = handoff..addListener(_onHandoff);
    }
    final station = context.read<MapStationHandoff>();
    if (station != _stationHandoff) {
      _stationHandoff?.removeListener(_onStationHandoff);
      _stationHandoff = station..addListener(_onStationHandoff);
    }
    final visibleTab = VisibleTabScope.of(context);
    if (identical(visibleTab, _visibleTab)) return;
    _visibleTab?.removeListener(_onTabChanged);
    _visibleTab = visibleTab;
    visibleTab?.addListener(_onTabChanged);
    _wasVisible = _isVisible;
  }

  /// Whether this surface is on screen — its branch selected and nothing pushed
  /// over the shell. A null tab (full-screen routes, previews) belongs to no
  /// branch, so only the shell test applies. Same contract as [BaseMap].
  bool get _isVisible =>
      _appForeground && (_visibleTab?.isOnScreen(widget.tabIndex) ?? true);

  /// Whether the app itself is in the foreground — the same definition
  /// [BaseMap] uses (`inactive` still counts as foreground, so a
  /// notification-shade pull does not flap the layers).
  bool _appForeground = true;

  /// [_isVisible] as of the last notification, so [_onTabChanged] can fire on
  /// the hidden → visible **edge** rather than on every notification where the
  /// map happens to be visible.
  ///
  /// The notifier reports two independent things (which branch is selected, and
  /// whether a page covers the shell), so without this a page pushed *over* the
  /// map would deliver a notification while the map is still the selected
  /// branch — and re-fetch the whole timeline for the act of opening settings,
  /// then again on the way back.
  bool _wasVisible = true;

  @override
  void dispose() {
    _visibleTab?.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    _bearing.dispose();
    _cameraEpoch.dispose();
    _scrubBackpressure.dispose();
    _showTownLabels.dispose();
    _showTerrain.dispose();
    _basemapWarmer?.cancel();
    _handoff?.removeListener(_onHandoff);
    _stationHandoff?.removeListener(_onStationHandoff);
    super.dispose();
  }

  /// The timeline's "now" and its frames went stale while this surface was
  /// off-screen — the app backgrounded, or the user sat on another tab.
  ///
  /// Re-fetch and re-centre on the present, but only when this map can be
  /// seen: the IndexedStack keeps hidden tabs mounted, and a hidden map has
  /// no timeline to update. Non-timeline layers are skipped entirely — their
  /// data sources (RTS, the mesh node store) refresh themselves, and a bare
  /// re-render would only flash the map.
  void _onTabChanged() {
    final visible = _isVisible;
    final changed = visible != _wasVisible;
    final returned = visible && !_wasVisible;
    _wasVisible = visible;
    // Both edges, before the timeline reload: a realtime layer skips its
    // platform uploads while hidden and flushes once on return.
    if (changed) _active.onSurfaceVisibility(visible);
    if (!returned) return;
    if (_active.usesTimeline) unawaited(_loadActive());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = switch (state) {
      AppLifecycleState.paused ||
      AppLifecycleState.hidden ||
      AppLifecycleState.detached => false,
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    };
    if (foreground != _appForeground) {
      _appForeground = foreground;
      // Backgrounding is the same edge as leaving the tab: realtime layers
      // stop their platform uploads (and their repaint tickers) while nobody
      // can see the map, and flush once on the way back.
      _onTabChanged();
    }
    if (state != AppLifecycleState.resumed || !_isVisible) return;
    // Coming back from the background is the same event as re-entering the
    // tab: what is on screen has been sitting there unattended. A radar frame
    // every 10 minutes means a half-hour away is three frames missed.
    if (_active.usesTimeline) unawaited(_loadActive());
  }

  /// A framing request arrived (map re-opened from Home / the nav bar) — apply it
  /// once the style is up. Leaves it pending if not, for [_onStyleLoaded].
  void _onHandoff() {
    if (!_styleLoaded) return;
    // A handoff usually arrives mid-navigation — the nav/home tap that requests
    // it switches tabs in the same gesture, so this map is still offstage in the
    // shell's IndexedStack and a moveCamera here would be dropped, stranding the
    // map on its previous view. Apply it next frame, once the switch has put the
    // map onstage, so re-entry reframes reliably.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_applyCameraHandoff());
    });
  }

  /// Station focus from ranking (or similar): layer + camera + sheet.
  void _onStationHandoff() {
    if (!_styleLoaded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_applyStationHandoff());
    });
  }

  /// Applies a pending camera (+ optional layer) hand-off from Home / nav.
  Future<void> _applyCameraHandoff() async {
    final pending = _handoff?.takePending();
    if (pending == null || !mounted) return;
    await _switchToLayerId(pending.layerId);
    if (!mounted) return;
    _frameBounds(pending.bounds, northUp: true);
  }

  /// Switches the active overlay when [layerId] is set and known.
  Future<void> _switchToLayerId(String? layerId) async {
    if (layerId == null || layerId == _active.id) return;
    MapLayer? layer;
    for (final candidate in widget.layers) {
      if (candidate.id == layerId) {
        layer = candidate;
        break;
      }
    }
    if (layer == null) {
      Log.warning('Map camera handoff: unknown layer $layerId');
      return;
    }
    _onLayerSelected(layer);
    await _mapOps;
  }

  Future<void> _applyStationHandoff() async {
    final pending = _stationHandoff?.takePending();
    if (pending == null || !mounted) return;

    await _switchToLayerId(pending.layerId);
    if (!mounted) return;
    _frameBounds(pending.bounds);

    // Wait for clear+render so station catalogue is loaded before select.
    await _mapOps;
    if (!mounted) return;
    if (_active.id != pending.layerId) return;
    _active.selectFeature(pending.stationId);
  }

  /// Adopts [bounds] as the framing target and applies it.
  void _frameBounds(LatLngBounds bounds, {bool northUp = false}) {
    _target = safeFitBounds(bounds);
    // The active layer's chrome height is measured, not predicted — a timeline
    // layer's panel only exists after its frames load. A deliberate framing
    // that runs before then fits against a zero-height band, so remember to
    // re-fit once [_measureTimeline] learns the real height.
    _reframeOnMeasure = _active.usesTimeline;
    _applyFraming(northUp: northUp);
  }

  /// Points the camera at [_target], fitted into the band the user can actually
  /// see right now.
  ///
  /// Re-run whenever that band changes — a layer switch, or the timeline being
  /// measured — because each layer covers a different amount of the map: radar
  /// puts a timeline along the bottom, a station layer a collapsed sheet, RTS a
  /// status strip. Keeping [_target] separate from the camera is what lets the
  /// same place stay framed across those switches (pick a township on Home, then
  /// switch to radar, and the township is still the subject).
  ///
  /// The fit is computed in Dart ([boundsFitCamera]) and applied as a plain
  /// centre+zoom, never MapLibre's native `newLatLngBounds` — that aborts the
  /// process on a degenerate box, and its padding is dropped on the `camera#move`
  /// path anyway (see camera_fit.dart).
  void _applyFraming({bool northUp = false}) {
    final target = _target;
    if (target == null || !mounted || _controller == null) return;
    // The map's own size, not MediaQuery's screen size: this surface sits inside
    // the shell, so the two differ by a device-dependent amount and a zoom
    // derived from the screen mis-frames.
    final size = _mapViewSize ?? MediaQuery.sizeOf(context);
    final fit = boundsFitCamera(
      target,
      viewport: size,
      topInset: MediaQuery.paddingOf(context).top,
      bottomInset: _bottomInset(size),
    );
    if (fit == null) return;
    // A re-entry frame (nav-bar / Home hand-off) snaps the camera back to
    // north-up: `newLatLngZoom` preserves the current heading on iOS
    // (Convert.swift keeps `camera.heading`), so a map left rotated would come
    // back rotated; `newCameraPosition` with bearing 0 always faces north.
    if (northUp) {
      _controller?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: fit.target,
            zoom: fit.zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      );
    } else {
      _controller?.moveCamera(CameraUpdate.newLatLngZoom(fit.target, fit.zoom));
    }
  }

  /// How much of the map's bottom the active layer's resting chrome hides: the
  /// layer's own declared share (a collapsed sheet, a status strip) plus the
  /// timeline, whose real height the scaffold measures because it owns it.
  double _bottomInset(Size size) =>
      size.height * _active.bottomChromeFraction + _timelineHeight;

  /// Measures the timeline panel after layout.
  ///
  /// The height feeds [_bottomInset] for the *next* deliberate framing (a nav-bar
  /// / Home entry), so that framing avoids the scrubber. It never moves the
  /// camera on its own — re-framing on a layer switch is exactly what was
  /// removed: switching overlays keeps the user's camera untouched. The one
  /// exception is a deferred deliberate framing ([_reframeOnMeasure]): it ran
  /// before this panel existed, so once the real height lands it re-fits the
  /// same target into the corrected band.
  void _measureTimeline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _timelineKey.currentContext?.findRenderObject() as RenderBox?;
      final height = (box != null && box.hasSize) ? box.size.height : 0.0;
      if ((height - _timelineHeight).abs() < 0.5) return;
      _timelineHeight = height;
      if (_reframeOnMeasure) {
        _reframeOnMeasure = false;
        _applyFraming();
      }
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    final tileCache = context.read<MapTileCache?>();
    _basemapWarmer ??= MapTileWarmer(tileCache);
    // Bootstrap can configure the cache before the platform-view plugin owns
    // this channel. Re-send the byte cap now so native L1 is actually 48 MB,
    // not its 2 MB pre-attach fallback.
    _tileCacheReady =
        tileCache?.syncNativeConfiguration() ?? Future<void>.value();
    unawaited(const MapCache().setMaximumSize());
  }

  /// Feeds the compass needle — camera heading, ° clockwise from north.
  void _onCameraMove(CameraPosition position) {
    // Pointer events cover direct pan/pinch gestures. Camera motion also covers
    // wheel, accessibility, double-tap, and programmatic zooms, so every route
    // keeps screen-space overlays hidden until the matching idle callback.
    _mapInteraction.cameraMoved();
    _bearing.value = position.bearing;
  }

  void _onMapPointerDown(PointerDownEvent event) {
    _mapInteraction.pointerDown(event.pointer);
  }

  void _onMapPointerEnded(PointerEvent event) {
    final cameraMoving = _controller?.isCameraMoving ?? false;
    if (_mapInteraction.pointerEnded(
      event.pointer,
      cameraMoving: cameraMoving,
    )) {
      // A tap does not produce another camera-idle event, but static overlays
      // may still react to it, so retain the old tap-settle rebuild.
      _cameraEpoch.value++;
    }
  }

  /// Re-points the camera north, keeping centre / zoom — the native compass's
  /// tap action, reproduced for the Flutter replacement.
  void _resetNorth() {
    final controller = _controller;
    if (controller == null) return;
    final position = controller.cameraPosition;
    if (position == null) return;
    // The camera stream may not deliver a final north-up event for a
    // programmatic move (a no-op bearing change can skip region updates), so
    // settle the needle directly instead of waiting on it — the compass must
    // hide the instant the map faces north.
    _bearing.value = 0;
    unawaited(
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position.target,
            zoom: position.zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      ),
    );
  }

  void _setShowTownLabels(bool value) {
    if (_showTownLabels.value == value) return;
    _showTownLabels.value = value;
    _applyTownLabelVisibility();
  }

  void _setShowTerrain(bool value) {
    if (_showTerrain.value == value) return;
    _showTerrain.value = value;
    if (!value) {
      unawaited(_basemapWarmer?.discardWorkingSet('terrain'));
    }
    _syncTerrain();
  }

  /// Pushes the terrain-relief setting onto a live map — by **adding and
  /// removing**, not by flipping `visibility`.
  ///
  /// MapLibre only stops loading a source's tiles when no layer references it:
  /// `visibility: none` merely stops rendering, so the DEM kept downloading,
  /// decoding and holding memory (roughly 1 MB of texture plus 1 MB of float
  /// mesh per 512px tile, ~49 tiles for a hillshade viewport) with the switch
  /// off. So off means removeLayer + removeSource — tiles, memory and network
  /// all released — and on re-adds both with the same id, source and paint the
  /// baked style used (see [_terrainSourceProps] / [_terrainLayerProps]).
  ///
  /// Style reloads re-bake both from the style string, so [_onStyleLoaded]
  /// re-asserts the user's choice here.
  void _syncTerrain() {
    final controller = _controller;
    if (controller == null) return;
    unawaited(_syncTerrainLoop(controller));
  }

  Future<void> _syncTerrainLoop(MapLibreMapController controller) async {
    // Loop until the map matches the setting: a rapid double-tap flips the
    // notifier while an add/remove is mid-flight, and each iteration re-reads
    // it, so the last tap always wins.
    var dirty = true;
    while (dirty) {
      dirty = false;
      final show = _showTerrain.value;
      try {
        if (show && !_terrainOnMap) {
          await controller.addSource(terrainSourceId, _terrainSourceProps);
          await controller.addHillshadeLayer(
            terrainSourceId,
            terrainHillshadeLayerId,
            _terrainLayerProps,
            belowLayerId: townOutlineLayerId,
          );
          _terrainOnMap = true;
        } else if (!show && _terrainOnMap) {
          await controller.removeLayer(terrainHillshadeLayerId);
          await controller.removeSource(terrainSourceId);
          _terrainOnMap = false;
        }
      } catch (error, stackTrace) {
        // A style that never baked the terrain has nothing to remove, and a
        // mid-reload call can race the native side. Log and stop; the next
        // toggle or style load re-syncs.
        Log.handle(error, stackTrace, 'terrain sync');
        return;
      }
      if (_showTerrain.value != show) dirty = true;
    }
  }

  /// Pushes the township-label setting onto a live map. The base style's
  /// `town-label` layer survives style reloads, which reset it to visible, so
  /// this also runs after every [_onStyleLoaded] to re-assert the choice.
  void _applyTownLabelVisibility() {
    final controller = _controller;
    if (controller == null) return;
    unawaited(
      controller
          .setLayerVisibility(townLabelLayerId, _showTownLabels.value)
          .catchError((Object e, StackTrace st) {
            Log.handle(e, st, 'Failed to sync the township labels');
          }),
    );
  }

  Future<void> _warmBasemap(MapLibreMapController controller) async {
    await _tileCacheReady;
    final warmer = _basemapWarmer;
    if (warmer == null) return;
    try {
      final bounds = await controller.getVisibleRegion();
      final zoom = controller.cameraPosition?.zoom ?? 8;
      await warmer.warmViewportAbsolute(
        urlFor: (z, x, y) => _basemapTileUrl
            .replaceAll('{z}', '$z')
            .replaceAll('{x}', '$x')
            .replaceAll('{y}', '$y'),
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
        maxZoom: 12,
        logLabel: 'basemap',
        workingSet: 'basemap',
        immediate: true,
      );
      // DEM tiles too — the relief renders at every zoom, so warm them the
      // same way as the basemap. Native downloads a hillshade viewport as one
      // burst of 512px meshes the first time; warming from the store makes a
      // repeat visit an SQLite hit instead of a re-download.
      //
      // Only while the relief is on: with it off the DEM source is removed
      // from the style, MapLibre will never request these tiles, and warming
      // them was a viewport of downloads per camera settle for pixels that
      // cannot be drawn. Gated on the toggle (the user's intent), not on
      // `_terrainOnMap`, which is transiently wrong mid style-reload.
      if (_showTerrain.value) {
        await warmer.warmViewportAbsolute(
          urlFor: (z, x, y) => terrainOriginTileUrl
              .replaceAll('{z}', '$z')
              .replaceAll('{x}', '$x')
              .replaceAll('{y}', '$y'),
          south: bounds.southwest.latitude,
          west: bounds.southwest.longitude,
          north: bounds.northeast.latitude,
          east: bounds.northeast.longitude,
          zoom: zoom,
          maxZoom: 12,
          logLabel: 'terrain',
          workingSet: 'terrain',
          immediate: true,
        );
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'basemap viewport warm');
    }
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    // Fires on the first load and again on every base-style reload (a theme /
    // dark-mode change), which wipes all runtime layers. Tell each layer to
    // forget its on-map state so the re-render re-adds instead of no-oping.
    for (final layer in widget.layers) {
      layer.onStyleReset();
    }
    // Frame once on first load — the view handed off by whoever opened the map
    // (Home's current view, or the nationwide default from the nav bar), else
    // the island. A reload keeps whatever the user has panned/zoomed to.
    if (!_framed) {
      _framed = true;
      final pending = _handoff?.takePending();
      // Home may force radar before the user's default overlay loads.
      if (pending?.layerId != null) {
        for (final layer in widget.layers) {
          if (layer.id == pending!.layerId) {
            _active = layer;
            break;
          }
        }
      }
      _frameBounds(pending?.bounds ?? BaseMap.taiwanBounds);
    }
    _loadActive();
    // Ranking may have queued a station focus before the style was ready.
    unawaited(_applyStationHandoff());
    // Home/nav camera handoff that arrived before the style was ready.
    unawaited(_applyCameraHandoff());
    // A reload resets the base style's township-label layer to visible.
    _applyTownLabelVisibility();
    // …and re-bakes the terrain source + hillshade layer, so re-assert the
    // user's choice — which removes both when the relief is off.
    _terrainOnMap = true;
    _syncTerrain();
  }

  /// Forwards a map tap to the active (sheet) layer — it selects the nearest
  /// feature, which opens its sheet.
  void _onMapClick(LatLng latLng) {
    final controller = _controller;
    if (controller == null || _active.usesTimeline) return;
    unawaited(_active.onMapTap(latLng, controller));
  }

  /// Renders the active layer: a sheet layer draws its static overlay; a
  /// timeline layer fetches its frames and reveals the newest.
  Future<void> _loadActive() async {
    await _tileCacheReady;
    if (_controller == null || !_styleLoaded) return;
    final gen = ++_generation;
    setState(() => _error = null);
    if (!_active.usesTimeline) {
      final controller = _controller!;
      final layer = _active;
      setState(() => _frames = const []);
      _queue(() => layer.render(controller));
      return;
    }
    final result = await _active.frames();
    if (!mounted || gen != _generation) return;
    result.when(
      ok: (frames) {
        setState(() {
          _frames = frames;
          // The calibrated clock, not device time: the frames are server
          // timestamps, and a device clock that drifted (or a timezone the
          // device changed) would pick the wrong "now" frame. The NTP resync
          // on foreground is what makes this actually correct after a
          // background stretch.
          _selectedIndex = nowFrameIndex(frames, now: AppTime.utc);
        });
        if (frames.isNotEmpty) {
          // Register the set, then reveal the present (a layer adds tiles
          // lazily). For observed data that is the newest frame; a forecast
          // opens on the newest already-due step, future steps to the right.
          final controller = _controller!;
          final layer = _active;
          _queue(() => layer.prepare(controller, frames));
          _showSelected();
        }
      },
      err: (failure) {
        Log.warning(
          'Map layer ${_active.id} frames failed: ${failure.message}',
        );
        setState(() {
          _frames = const [];
          _error = failure;
        });
      },
    );
  }

  void _showSelected() {
    final controller = _controller;
    if (controller == null) return;
    final layer = _active;
    // Already queued: that op will pick up this newer selection when it runs, so
    // don't stack another one (see [_showQueued]).
    if (_showQueued) {
      if (_scrubbing) _scrubBackpressure.reportDroppedFrame();
      return;
    }
    _showQueued = true;
    _queue(() {
      // Cleared as the op *starts*, not when it finishes: a selection arriving
      // while this render is in flight then queues exactly one follow-up, so the
      // final scrub position is always rendered and never more than one op waits.
      _showQueued = false;
      if (_frames.isEmpty || !identical(layer, _active)) {
        return Future<void>.value();
      }
      // Read index + scrubbing at execution time so a settle that landed while
      // this op was queued still mounts (pending scrub ops must not cold-skip).
      return layer.show(
        controller,
        _frames[_selectedIndex],
        scrubbing: _scrubbing,
      );
    });
  }

  void _onScrubbing(bool scrubbing) {
    final was = _scrubbing;
    _scrubbing = scrubbing;
    if (!scrubbing) _scrubBackpressure.resume();
    // Finger up: force a settle mount for the current index (may be cold).
    if (was && !scrubbing) _showSelected();
  }

  void _onFrameSelected(int index) {
    if (index < 0 || index >= _frames.length || index == _selectedIndex) return;
    // No setState: the map is updated imperatively via show(), so scrubbing
    // never rebuilds the (expensive) platform-view map. The timeline drives its
    // own display; _selectedIndex is just the source of truth for show().
    _selectedIndex = index;
    // Scrub and settle share the same serial latest-wins lane. Letting scrub
    // call show() directly allowed the finger-up settle to mutate the same
    // MapLibre layers concurrently with an older in-flight reveal.
    _showSelected();
  }

  void _onLayerSelected(MapLayer layer) {
    if (layer.id == _active.id) return;
    final controller = _controller;
    final previous = _active;
    // Invalidate in-flight loads/renders of the previous layer.
    _generation++;
    setState(() {
      _active = layer;
      _frames = const [];
      _error = null;
      // The old layer's chrome is gone; the new one measures itself (a timeline
      // layer re-measures in build, a sheet layer declares its own share).
      _timelineHeight = 0;
    });
    if (controller != null) _queue(() => previous.clear(controller));
    // A bare switch is never a deliberate framing — the camera stays exactly as
    // the user left it, and the [_reframeOnMeasure] deferred re-fit must not
    // fire off it either (the height will change as the new layer's frames
    // load, and that is a reason to *not* move the camera).
    _reframeOnMeasure = false;
    // Keep the camera exactly as the user left it — switching overlays must not
    // zoom, re-centre, or rotate the map. Only a deliberate framing entry (the
    // nav bar / Home hand-off, or a ranking station focus) moves the camera.
    _loadActive();
  }

  /// Re-loads the active layer from scratch: clear its on-map state (sources
  /// mounted under the old URLs), then re-fetch frames and re-mount. A chrome
  /// option that changes what a layer renders (e.g. the satellite colour style)
  /// calls this after mutating its source.
  Future<void> _reloadActive() async {
    final controller = _controller;
    if (controller == null || !_styleLoaded) return;
    final layer = _active;
    // Clear first — the queued re-mount ops below land after it on the serial
    // chain, so the map never shows new-style tiles over old ones.
    _queue(() => layer.clear(controller));
    await _loadActive();
  }

  /// Appends [op] to the serial controller-op chain, logging any failure — a
  /// failed overlay op degrades the map, it never throws into the tree.
  void _queue(Future<void> Function() op) {
    _mapOps = _mapOps.then((_) => op()).catchError((Object e, StackTrace st) {
      Log.handle(e, st, 'Map layer op failed (${_active.id})');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final measured = constraints.biggest;
          if (measured.isFinite) _mapViewSize = measured;
          return _body(context);
        },
      ),
    );
  }

  Widget _body(BuildContext context) {
    // The timeline's height depends on its content, so measure it after every
    // build; a change re-frames (see [_measureTimeline]).
    if (_active.usesTimeline) _measureTimeline();
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onMapPointerDown,
            onPointerUp: _onMapPointerEnded,
            onPointerCancel: _onMapPointerEnded,
            child: BaseMap(
              minZoomPreference: _active.mapMinZoom,
              maxZoomPreference: _active.mapMaxZoom,
              // The map tab owns this surface — pause native rendering when the
              // user is on another tab (indexedStack keeps it mounted).
              tabIndex: widget.tabIndex,
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
              onMapClick: (_, latLng) => _onMapClick(latLng),
              onCameraMove: _onCameraMove,
              onCameraIdle: () {
                _mapInteraction.cameraIdle();
                final controller = _controller;
                if (controller != null) {
                  unawaited(_active.onCameraIdle(controller));
                  unawaited(_warmBasemap(controller));
                }
                // An idle callback can arrive while a finger is still held
                // stationary. Keep overlays hidden until the last pointer is
                // released, then rebuild once against the final camera.
                if (!_mapInteraction.hasPointers) _cameraEpoch.value++;
              },
              // The native compass lives inside the platform view, so any
              // Flutter overlay paints over it — MapScaffold draws its own
              // [MapCompass] at the top of the stack instead.
              compassEnabled: false,
            ),
          ),
        ),
        // Screen-space Flutter overlays (e.g. typhoon forecast tips) — under
        // chrome/sheet so they don't steal taps; IgnorePointer keeps pan/zoom.
        // Only this subtree rebuilds on a camera settle (ValueListenableBuilder
        // + keyed reprojection); the map and chrome stay put.
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<int>(
              valueListenable: _cameraEpoch,
              builder: (context, epoch, _) => KeyedSubtree(
                // The epoch is in the key only for overlays that project once
                // per build: changing it discards the subtree's State, which is
                // the point for a callout and ruinous for an animation that
                // owns a ticker and a frame buffer.
                key: ValueKey<Object>(
                  _active.overlayFollowsCamera
                      ? '${_active.id}-$epoch'
                      : _active.id,
                ),
                child: _active.buildMapOverlay(context),
              ),
            ),
          ),
        ),
        // Colour / key legend — top-left. Under the sheet so a dragged-up
        // sheet covers it instead of sitting behind a floating chip.
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CollapsibleMapLegend(
                key: ValueKey(_active.id),
                legend: _active.buildLegend(context),
              ),
            ),
          ),
        ),
        // Layer switcher (+ optional layer chrome) — top-right.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Builder(
                builder: (context) {
                  // Layers with a settings menu (radar / QPESUMS / DPM / typhoon
                  // / rain) receive the shared township-label toggle to carry;
                  // the rest return [SizedBox.shrink], so show the standalone
                  // township-label menu instead — every layer can set it.
                  final chrome = _active.buildTopTrailingChrome(
                    context,
                    showTownLabels: _showTownLabels,
                    onShowTownLabelsChanged: _setShowTownLabels,
                    showTerrain: _showTerrain,
                    onShowTerrainChanged: _setShowTerrain,
                    onReloadActive: _reloadActive,
                  );
                  final hasChrome = chrome is! SizedBox;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasChrome) ...[
                        chrome,
                        const SizedBox(width: AppSpacing.sm),
                      ] else ...[
                        MapBasemapMenu(
                          showTownLabels: _showTownLabels,
                          onShowTownLabelsChanged: _setShowTownLabels,
                          showTerrain: _showTerrain,
                          onShowTerrainChanged: _setShowTerrain,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      MapLayerSwitcher(
                        layers: widget.layers,
                        active: _active,
                        onSelected: _onLayerSelected,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Sheet / timeline last so they paint above the chrome when expanded.
        if (!_active.usesTimeline)
          Positioned.fill(child: _active.buildSheet(context)),
        if (_active.usesTimeline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              key: _timelineKey,
              top: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _frames.isNotEmpty
                      ? _timelinePanel(context)
                      : _error != null
                      ? _errorPanel(context)
                      : const SizedBox.shrink(),
                  if (_frames.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      child: IgnorePointer(
                        child: Transform.translate(
                          offset: const Offset(0, -AppSpacing.sm),
                          child: FractionalTranslation(
                            translation: const Offset(0, -1),
                            child: MapTimelineScrubPauseNotice(
                              paused: _scrubBackpressure,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Compass on top of *everything* — a screen-space callout (typhoon
        // forecast tips) or an expanded sheet must never hide north. Parked
        // just under the layer switcher chip, with a touch of breathing room.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: layerChipBand + AppSpacing.sm,
                right: AppSpacing.lg,
              ),
              child: MapCompass(bearing: _bearing, onPressed: _resetNorth),
            ),
          ),
        ),
      ],
    );
  }

  /// Compact, recoverable strip when the active layer's frames fail — the base
  /// map still shows, so this degrades the overlay rather than blanking the map.
  Widget _errorPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FrostedSurface(
      borderRadius: AppRadius.large,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          // The bottom-nav clearance is the SafeArea wrapper's job (see build);
          // adding MediaQuery's bottom inset here too double-counted it.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _error!.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(onPressed: _loadActive, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelinePanel(BuildContext context) {
    // Only raster-timeline layers reach here (the usesTimeline gate); the
    // caption is theirs to say — observed vs forecast — so forecast frames are
    // never read as measurements. Anything else falls back to "observed".
    final active = _active;
    final isRaster = active is RasterTimelineLayer;
    final caption = isRaster
        ? active.timelineCaption(context)
        : AppLocalizations.of(context).mapTimelineObserved;
    final framePeriod = isRaster ? active.framePeriod : null;
    final dataTime = isRaster ? active.modelRunTime : null;
    return FrostedSurface(
      borderRadius: AppRadius.large,
      child: Padding(
        // The bottom-nav clearance is the SafeArea wrapper's job (see build);
        // adding MediaQuery's bottom inset here too made the panel very tall.
        padding: const EdgeInsets.all(AppSpacing.md),
        child: MapTimeline(
          frames: _frames,
          selectedIndex: _selectedIndex,
          onSelected: _onFrameSelected,
          onScrubbing: _onScrubbing,
          caption: caption,
          framePeriod: framePeriod,
          dataTime: dataTime,
        ),
      ),
    );
  }
}
