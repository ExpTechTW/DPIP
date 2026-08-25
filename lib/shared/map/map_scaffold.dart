import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
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
import 'package:dpip/shared/map/basemap_overlay_sync.dart';
import 'package:dpip/shared/map/map_gsi_overlay.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/map/map_trace.dart';
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
    this.initialOsmEnabled = false,
    this.tabIndex,
  }) : assert(layers.length > 0, 'MapScaffold needs at least one layer');

  /// The layers this surface offers; [initialLayerId] (or the first entry) is
  /// shown initially.
  final List<MapLayer> layers;

  /// Preferred overlay id (`MapLayer.id`) when the surface mounts. Unknown /
  /// missing → [layers].first.
  final String? initialLayerId;

  /// Whether this surface starts on the detailed OSM base instead of terrain.
  /// This is an initial preference only; the shared map menu remains in charge
  /// after mount. The disaster-prevention map page opts in.
  final bool initialOsmEnabled;

  /// Shell tab owning this surface — forwarded to [BaseMap] so the map pauses
  /// its native render loop while the tab is hidden. `null` never pauses.
  final int? tabIndex;

  @override
  State<MapScaffold> createState() => _MapScaffoldState();
}

class _MapScaffoldState extends State<MapScaffold> with WidgetsBindingObserver {
  final int _traceId = nextMapTraceId();
  final Stopwatch _traceClock = Stopwatch()..start();
  Timer? _traceHeartbeat;
  int _lastHeartbeatMs = 0;
  int _loadSequence = 0;
  int _mapOpSequence = 0;
  int _pendingMapOps = 0;
  int _controllerEpoch = 0;

  String get _traceScope => 'scaffold#$_traceId/tab=${widget.tabIndex}';

  void _trace(String Function() message) => mapTrace(_traceScope, message);

  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  CameraPosition? _cameraBeforeRecreate;
  bool _restoreSurfaceAfterRecreate = false;
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

  /// Hidden-layer set. Watched directly (not via the parent remounting on a
  /// [ValueKey] change) so hiding the on-screen layer falls back through
  /// [_onLayerSelected] in place — a remount would tear down this State and
  /// close any sheet open above it, such as the layer-order editor the hide
  /// itself was just tapped from.
  MapLayerVisibilityController? _visibility;

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
  /// base-map property, so it lives beside [_showTownLabels]. It normally
  /// starts on; the disaster-prevention surface starts on OSM instead.
  final ValueNotifier<bool> _showTerrain = ValueNotifier(true);

  /// Optional Taiwan street/building detail drawn over the ordinary base map.
  /// It is absent by default except on an OSM-first surface such as the
  /// disaster-prevention map.
  late final GsiOverlayController _gsi;

  /// Backs [_gsi] plus the [_showTerrain] / [_showTownLabels] persistence —
  /// read once in [initState], since none of these three toggles need to
  /// react to a settings change made elsewhere while this surface is open.
  late final SettingsStore _settings;

  /// Applies the base-map toggles to the live controller (see
  /// [_syncBasemapOverlays]); shared with the report-detail page.
  final BasemapOverlaySync _basemapSync = BasemapOverlaySync();

  bool _gsiZoomEnabled = false;

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
    _trace(() => 'init active=${_active.id} timeline=${_active.usesTimeline}');
    _scrubBackpressure.addListener(_onScrubBackpressureChanged);
    _settings = context.read<SettingsStore>();
    _showTerrain.value = _settings.getBool(SettingKeys.mapShowTerrain) ?? true;
    _showTownLabels.value =
        _settings.getBool(SettingKeys.mapShowTownLabels) ?? true;
    _gsi = GsiOverlayController(
      _settings,
      mutuallyExclusiveTerrain: _showTerrain,
      forceEnabled: widget.initialOsmEnabled,
    );
    _gsiZoomEnabled = _gsi.enabled;
    _gsi.addListener(_onGsiChanged);
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
    final visibility = context.read<MapLayerVisibilityController>();
    if (visibility != _visibility) {
      _visibility?.removeListener(_onVisibilityChanged);
      _visibility = visibility..addListener(_onVisibilityChanged);
    }
    final visibleTab = VisibleTabScope.of(context);
    if (identical(visibleTab, _visibleTab)) return;
    _visibleTab?.removeListener(_onTabChanged);
    _visibleTab = visibleTab;
    visibleTab?.addListener(_onTabChanged);
    _wasVisible = _isVisible;
    // An IndexedStack branch may be created before it is ever selected. Give
    // the layer its initial visibility too; waiting for the first notifier edge
    // would let an off-screen first style load start a full timeline warm.
    _active.onSurfaceVisibility(_wasVisible);
    _trace(
      () =>
          'visible-scope attached scope=${mapTraceObject(visibleTab)} '
          'selected=${visibleTab?.value} shellOnTop=${visibleTab?.shellOnTop} '
          'visible=$_wasVisible',
    );
    _syncTraceHeartbeat(_wasVisible);
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

  void _syncTraceHeartbeat(bool visible) {
    if (!mapTraceEnabled) return;
    if (!visible) {
      if (_traceHeartbeat != null) _trace(() => 'watchdog stop hidden');
      _traceHeartbeat?.cancel();
      _traceHeartbeat = null;
      return;
    }
    if (_traceHeartbeat != null) return;
    _lastHeartbeatMs = _traceClock.elapsedMilliseconds;
    _trace(
      () =>
          'watchdog start controller=${mapTraceObject(_controller)} '
          'style=$_styleLoaded',
    );
    _traceHeartbeat = Timer.periodic(const Duration(seconds: 3), (_) {
      final now = _traceClock.elapsedMilliseconds;
      final gap = now - _lastHeartbeatMs;
      _lastHeartbeatMs = now;
      _trace(
        () =>
            'heartbeat gap=${gap}ms controller=${mapTraceObject(_controller)} '
            'style=$_styleLoaded active=${_active.id} gen=$_generation '
            'frames=${_frames.length} selected=$_selectedIndex '
            'pendingOps=$_pendingMapOps showQueued=$_showQueued '
            'scrubbing=$_scrubbing',
      );
    });
  }

  @override
  void dispose() {
    _trace(
      () =>
          'dispose controller=${mapTraceObject(_controller)} '
          'pendingOps=$_pendingMapOps',
    );
    _traceHeartbeat?.cancel();
    _visibleTab?.removeListener(_onTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    _bearing.dispose();
    _cameraEpoch.dispose();
    _scrubBackpressure.removeListener(_onScrubBackpressureChanged);
    _scrubBackpressure.dispose();
    _showTownLabels.dispose();
    _showTerrain.dispose();
    _gsi.removeListener(_onGsiChanged);
    _gsi.dispose();
    _basemapWarmer?.cancel();
    _handoff?.removeListener(_onHandoff);
    _stationHandoff?.removeListener(_onStationHandoff);
    _visibility?.removeListener(_onVisibilityChanged);
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
    _trace(
      () =>
          'visible-notify selected=${_visibleTab?.value} '
          'shellOnTop=${_visibleTab?.shellOnTop} visible=$visible '
          'changed=$changed returned=$returned active=${_active.id} '
          'style=$_styleLoaded controller=${mapTraceObject(_controller)}',
    );
    _wasVisible = visible;
    // Both edges, before the timeline reload: a realtime layer skips its
    // platform uploads while hidden and flushes once on return.
    if (changed) _active.onSurfaceVisibility(visible);
    _syncTraceHeartbeat(visible);
    if (!returned) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _trace(
        () =>
            'return-post-frame size=$_mapViewSize '
            'controller=${mapTraceObject(_controller)} style=$_styleLoaded',
      );
    });
    // The retained native view resumes in place on both platforms. If iOS fails
    // to produce a verified frame, BaseMap invalidates this generation before
    // remounting, so work started here cannot attach to the replacement style.
    if (_active.usesTimeline) {
      unawaited(_loadActive(trigger: 'tab-return'));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = switch (state) {
      AppLifecycleState.paused ||
      AppLifecycleState.hidden ||
      AppLifecycleState.detached => false,
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    };
    _trace(() => 'app-lifecycle state=$state foreground=$foreground');
    if (foreground != _appForeground) {
      _appForeground = foreground;
      // Backgrounding is the same edge as leaving the tab: realtime layers
      // stop their platform uploads (and their repaint tickers) while nobody
      // can see the map, and flush once on the way back.
      _onTabChanged();
    }
    // The false → true edge above already reloads a visible timeline. Doing it
    // again here queued the same prepare/show pair twice on every foreground
    // return. `inactive → resumed` has never hidden the map, so it needs neither
    // a render resume nor a timeline refetch.
  }

  /// The OS is short on memory and asked for caches back.
  ///
  /// Android delivers this from `onTrimMemory` at `TRIM_MEMORY_RUNNING_LOW`
  /// and above; `RUNNING_CRITICAL` is the last notice before lmkd chooses a
  /// victim. Returning nothing is how a process becomes that victim — DPIP was
  /// OOM-killed at ~1 GB resident, 341 MB of it decoded raster textures held
  /// by mounted timeline sources, with no code path willing to drop any of it.
  ///
  /// Only the active layer is asked: an inactive one holds no mounted sources
  /// (`_onLayerSelected` clears it on the way out). The image cache is Flutter's
  /// own and is rebuilt on demand.
  @override
  void didHaveMemoryPressure() {
    final controller = _controller;
    _trace(
      () =>
          'memory-pressure active=${_active.id} '
          'controller=${controller != null}',
    );
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (controller == null) return;
    _queue(
      () => _active.onMemoryPressure(controller),
      label: '${_active.id}.memory-pressure',
    );
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
    // A nav request can schedule this callback one frame before BaseMap
    // invalidates its retained iOS view. Do not consume the one-shot request
    // until its replacement controller and style are ready.
    if (!mounted || !_styleLoaded || _controller == null) return;
    final pending = _handoff?.takePending();
    if (pending == null) return;
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
    _trace(() => 'map-created controller=${mapTraceObject(controller)}');
    final tileCache = context.read<MapTileCache?>();
    _basemapWarmer ??= MapTileWarmer(tileCache);
    // Bootstrap can configure the cache before the platform-view plugin owns
    // this channel. Re-send the byte cap now so native L1 is actually 48 MB,
    // not its 2 MB pre-attach fallback.
    final cacheSync = Stopwatch()..start();
    _trace(() => 'tile-cache-sync start cache=${mapTraceObject(tileCache)}');
    _tileCacheReady =
        (tileCache?.syncNativeConfiguration() ?? Future<void>.value()).then(
          (_) {
            _trace(
              () =>
                  'tile-cache-sync done dt=${cacheSync.elapsedMilliseconds}ms',
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            _trace(
              () =>
                  'tile-cache-sync error dt=${cacheSync.elapsedMilliseconds}ms '
                  'error=$error',
            );
            return Future<void>.error(error, stackTrace);
          },
        );
    unawaited(const MapCache().setMaximumSize());
  }

  /// Detaches every style-bound owner from an iOS platform view immediately
  /// before BaseMap replaces it. The tile stores remain intact, so the new map
  /// rehydrates from L1/L2 instead of downloading the timeline again.
  void _onMapInvalidated(MapLibreMapController controller) {
    _cameraBeforeRecreate = controller.cameraPosition;
    _trace(
      () =>
          'map-invalidated controller=${mapTraceObject(controller)} '
          'camera=$_cameraBeforeRecreate pendingOps=$_pendingMapOps',
    );
    _generation++;
    _controllerEpoch++;
    _showQueued = false;
    _styleLoaded = false;
    _controller = null;
    _basemapWarmer?.cancel();
    _restoreSurfaceAfterRecreate = true;
    if (_active case final RasterTimelineLayer timeline) {
      timeline.onControllerInvalidated();
    }
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
    unawaited(_settings.setBool(SettingKeys.mapShowTownLabels, value));
    _applyTownLabelVisibility();
  }

  void _setShowTerrain(bool value) {
    // These are alternative base surfaces, not two independent overlays.
    // Disable OSM before publishing terrain=true so listeners never observe a
    // stable state in which both sources are selected.
    if (value && _gsi.enabled) _gsi.setEnabled(false);
    if (_showTerrain.value == value) return;
    _showTerrain.value = value;
    unawaited(_settings.setBool(SettingKeys.mapShowTerrain, value));
    if (!value) {
      unawaited(_basemapWarmer?.discardWorkingSet('terrain'));
    }
    _syncBasemapOverlays();
  }

  void _onGsiChanged() {
    // GsiOverlayController performs this edge synchronously for menu taps;
    // retain the guard for any controller restored by future persistence code.
    if (_gsi.enabled && _showTerrain.value) {
      _showTerrain.value = false;
      unawaited(_basemapWarmer?.discardWorkingSet('terrain'));
    }
    if (_gsiZoomEnabled != _gsi.enabled) {
      _gsiZoomEnabled = _gsi.enabled;
      if (mounted) setState(() {});
    }
    if (!_gsi.enabled) {
      unawaited(_basemapWarmer?.discardWorkingSet(gsiSourceId));
    } else if (_controller case final controller?) {
      // Toggling a stationary map produces no camera-idle callback. Warm the
      // current viewport now so repeat visits can reveal from L2 → L1 while
      // the native source is being attached, instead of waiting for a pan.
      unawaited(_warmGsi(controller));
    }
    _syncBasemapOverlays();
  }

  /// Reconciles the two mutually-exclusive detailed base surfaces in one map
  /// operation. Removing the old source always happens before adding the new
  /// one, so their native tile/decode work cannot overlap during a switch.
  void _syncBasemapOverlays() {
    final controller = _controller;
    if (!mounted || controller == null || !_styleLoaded) return;
    final brightness = Theme.of(context).brightness;
    _queue(
      () => _basemapSync.sync(
        controller,
        showTerrain: () => _showTerrain.value,
        gsi: _gsi,
        brightness: brightness,
        stillCurrent: () =>
            mounted && identical(controller, _controller) && _styleLoaded,
      ),
      label: 'basemap-overlays',
    );
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
      if (_gsi.enabled) {
        await _warmGsiViewport(warmer, bounds, zoom);
      }
      // DEM tiles too — the relief renders at every zoom, so warm them the
      // same way as the basemap. Native downloads a hillshade viewport as one
      // burst of 512px meshes the first time; warming from the store makes a
      // repeat visit an SQLite hit instead of a re-download.
      //
      // Only while the relief is on: with it off the DEM source is removed
      // from the style, MapLibre will never request these tiles, and warming
      // them was a viewport of downloads per camera settle for pixels that
      // cannot be drawn. Gated on the toggle (the user's intent), not on the
      // applier's on-map flag, which is transiently wrong mid style-reload.
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

  Future<void> _warmGsi(MapLibreMapController controller) async {
    await _tileCacheReady;
    final warmer = _basemapWarmer;
    if (warmer == null ||
        !_gsi.enabled ||
        !identical(controller, _controller)) {
      return;
    }
    try {
      final bounds = await controller.getVisibleRegion();
      if (!_gsi.enabled || !identical(controller, _controller)) return;
      await _warmGsiViewport(
        warmer,
        bounds,
        controller.cameraPosition?.zoom ?? 8,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'OSM viewport warm');
    }
  }

  Future<void> _warmGsiViewport(
    MapTileWarmer warmer,
    LatLngBounds bounds,
    double zoom,
  ) => warmer.warmViewportAbsolute(
    urlFor: (z, x, y) => gsiOriginTileUrl
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y'),
    south: bounds.southwest.latitude,
    west: bounds.southwest.longitude,
    north: bounds.northeast.latitude,
    east: bounds.northeast.longitude,
    zoom: zoom,
    maxZoom: gsiSourceMaxZoom.toInt(),
    logLabel: gsiSourceId,
    workingSet: gsiSourceId,
    immediate: true,
  );

  void _onStyleLoaded() {
    _styleLoaded = true;
    final cameraBeforeRecreate = _cameraBeforeRecreate;
    _cameraBeforeRecreate = null;
    _trace(
      () =>
          'style-loaded controller=${mapTraceObject(_controller)} '
          'framed=$_framed active=${_active.id}',
    );
    // Fires on the first load and again on every base-style reload (a theme /
    // dark-mode change), which wipes all runtime layers. Tell each layer to
    // forget its on-map state so the re-render re-adds instead of no-oping.
    for (final layer in widget.layers) {
      layer.onStyleReset();
    }
    if (_restoreSurfaceAfterRecreate) {
      _restoreSurfaceAfterRecreate = false;
      // Invalidation forced the active timeline hidden without sending native
      // cleanup to a controller that was already being destroyed. Reveal it
      // only after the replacement style exists, then its first settle can
      // refresh repaired tile bytes before mounting raster sources.
      _active.onSurfaceVisibility(_wasVisible);
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
    } else if (!(_handoff?.hasPending ?? false) &&
        cameraBeforeRecreate != null) {
      // A platform-view replacement starts at BaseMap's placeholder camera.
      // Restore the exact prior centre/zoom/bearing unless this return carries
      // a deliberate Home/nav framing request, which must win instead.
      unawaited(
        _controller?.moveCamera(
          CameraUpdate.newCameraPosition(cameraBeforeRecreate),
        ),
      );
      _trace(() => 'camera-restored after native recreate');
    }
    unawaited(_loadActive(trigger: 'style-loaded'));
    // Ranking may have queued a station focus before the style was ready.
    unawaited(_applyStationHandoff());
    // Home/nav camera handoff that arrived before the style was ready.
    unawaited(_applyCameraHandoff());
    // A reload resets the base style's township-label layer to visible.
    _applyTownLabelVisibility();
    // A regular surface bakes terrain into the base style; OSM-first surfaces
    // omit it, so the native mirror starts on whichever the style declares.
    _basemapSync.onStyleLoaded(bakedTerrain: !widget.initialOsmEnabled);
    _syncBasemapOverlays();
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
  Future<void> _loadActive({String trigger = 'direct'}) async {
    final loadId = ++_loadSequence;
    final elapsed = Stopwatch()..start();
    _trace(
      () =>
          'load#$loadId start trigger=$trigger active=${_active.id} '
          'timeline=${_active.usesTimeline} cache-await',
    );
    await _tileCacheReady;
    _trace(
      () =>
          'load#$loadId cache-ready dt=${elapsed.elapsedMilliseconds}ms '
          'controller=${mapTraceObject(_controller)} style=$_styleLoaded',
    );
    if (_controller == null || !_styleLoaded) {
      _trace(() => 'load#$loadId skip not-ready');
      return;
    }
    final gen = ++_generation;
    setState(() => _error = null);
    if (!_active.usesTimeline) {
      final controller = _controller!;
      final layer = _active;
      setState(() => _frames = const []);
      _queue(
        () => layer.render(controller),
        label: 'load#$loadId ${layer.id}.render',
      );
      _trace(() => 'load#$loadId queued render gen=$gen');
      return;
    }
    _trace(() => 'load#$loadId frames start gen=$gen');
    final result = await _active.frames();
    _trace(
      () =>
          'load#$loadId frames done dt=${elapsed.elapsedMilliseconds}ms '
          'mounted=$mounted gen=$gen currentGen=$_generation',
    );
    if (!mounted || gen != _generation) {
      _trace(() => 'load#$loadId discard stale');
      return;
    }
    result.when(
      ok: (frames) {
        _trace(
          () =>
              'load#$loadId frames ok count=${frames.length} '
              'dt=${elapsed.elapsedMilliseconds}ms',
        );
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
          _queue(
            () => layer.prepare(controller, frames),
            label: 'load#$loadId ${layer.id}.prepare',
          );
          _showSelected();
        }
      },
      err: (failure) {
        _trace(
          () =>
              'load#$loadId frames error dt=${elapsed.elapsedMilliseconds}ms '
              'message=${failure.message}',
        );
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
    // Once sustained input has genuinely outrun the render lane, stop feeding
    // it more work. The timeline label still follows the finger; the latest
    // selected index is submitted once its crossed-frame rate becomes safe.
    if (_scrubbing && _scrubBackpressure.value) {
      _scrubBackpressure.reportScrubSample();
      return;
    }
    // Already queued: that op will pick up this newer selection when it runs, so
    // don't stack another one (see [_showQueued]).
    if (_showQueued) {
      if (_scrubbing) _scrubBackpressure.reportDroppedFrame();
      return;
    }
    _showQueued = true;
    _queue(() async {
      // Cleared as the op *starts*, not when it finishes: a selection arriving
      // while this render is in flight then queues exactly one follow-up, so the
      // final scrub position is always rendered and never more than one op waits.
      _showQueued = false;
      if (_frames.isEmpty || !identical(layer, _active)) {
        return;
      }
      // Read index + scrubbing at execution time so a settle that landed while
      // this op was queued still mounts (pending scrub ops must not cold-skip).
      final index = _selectedIndex;
      final frame = _frames[index];
      final scrubbing = _scrubbing;
      await layer.show(controller, frame, scrubbing: scrubbing);
      // Queue drops are not the only way Android can suspend visual output. A
      // cold raster frame returns after its L1-only readiness probe while the
      // previous complete timestamp remains visible. Report that *actual*
      // hold, but ignore an older operation whose selection changed in flight.
      if (scrubbing &&
          _scrubbing &&
          index == _selectedIndex &&
          identical(layer, _active) &&
          layer is RasterTimelineLayer &&
          !layer.isShowingFrame(frame.id)) {
        _scrubBackpressure.reportBlockedFrame();
      }
    }, label: '${layer.id}.show');
  }

  void _onScrubBackpressureChanged() {
    final paused = _scrubBackpressure.value;
    _trace(
      () =>
          'scrub-backpressure ${paused ? 'paused' : 'resumed'} '
          'selected=$_selectedIndex pending=$_pendingMapOps '
          'showQueued=$_showQueued scrubbing=$_scrubbing',
    );
    // A quiet interval while the finger is still down is the promised
    // "slow down to resume" path. Submit the latest position once; if a
    // waiting show already exists it reads that same index when it starts.
    if (!paused && _scrubbing && !_showQueued) _showSelected();
  }

  void _onScrubbing(bool scrubbing) {
    final was = _scrubbing;
    _scrubbing = scrubbing;
    _trace(
      () =>
          'timeline-scrubbing from=$was to=$scrubbing selected=$_selectedIndex '
          'pending=$_pendingMapOps showQueued=$_showQueued',
    );
    if (!was && scrubbing) _active.onTimelineScrubStart();
    if (!scrubbing) _scrubBackpressure.resume();
    // Finger up: force a settle mount for the current index (may be cold).
    if (was && !scrubbing) _showSelected();
  }

  void _onFrameSelected(int index) {
    _trace(
      () =>
          'timeline-select requested=$index current=$_selectedIndex '
          'frames=${_frames.length} scrubbing=$_scrubbing '
          'pending=$_pendingMapOps showQueued=$_showQueued',
    );
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
    if (controller != null) {
      _queue(
        () => previous.clear(controller),
        label: '${previous.id}.clear-for-switch',
      );
    }
    // The disaster-prevention points need streets, buildings, and place names
    // as context. Its stable wire id is `dpm`, so entering it adopts OSM as the
    // layer's default; the menu can still switch back to terrain afterwards.
    if (layer.id == 'dpm' && !_gsi.enabled) _gsi.setEnabled(true);
    // A bare switch is never a deliberate framing — the camera stays exactly as
    // the user left it, and the [_reframeOnMeasure] deferred re-fit must not
    // fire off it either (the height will change as the new layer's frames
    // load, and that is a reason to *not* move the camera).
    _reframeOnMeasure = false;
    // Keep the camera exactly as the user left it — switching overlays must not
    // zoom, re-centre, or rotate the map. Only a deliberate framing entry (the
    // nav bar / Home hand-off, or a ranking station focus) moves the camera.
    unawaited(_loadActive(trigger: 'layer-selected'));
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
    _queue(
      () => layer.clear(controller),
      label: '${layer.id}.clear-for-reload',
    );
    await _loadActive(trigger: 'reload');
  }

  /// Appends [op] to the serial controller-op chain, logging any failure — a
  /// failed overlay op degrades the map, it never throws into the tree.
  void _queue(Future<void> Function() op, {String label = 'layer-op'}) {
    final opId = ++_mapOpSequence;
    final controllerEpoch = _controllerEpoch;
    _pendingMapOps++;
    _trace(() => 'op#$opId queued label=$label pending=$_pendingMapOps');
    _mapOps = _mapOps.then((_) async {
      final elapsed = Stopwatch()..start();
      if (controllerEpoch != _controllerEpoch) {
        _pendingMapOps--;
        _trace(
          () =>
              'op#$opId skip stale-controller label=$label '
              'epoch=$controllerEpoch current=$_controllerEpoch '
              'pending=$_pendingMapOps',
        );
        return;
      }
      _trace(() => 'op#$opId start label=$label pending=$_pendingMapOps');
      try {
        await op();
        _trace(
          () =>
              'op#$opId done label=$label dt=${elapsed.elapsedMilliseconds}ms',
        );
      } catch (error, stackTrace) {
        _trace(
          () =>
              'op#$opId error label=$label dt=${elapsed.elapsedMilliseconds}ms '
              'error=$error',
        );
        Log.handle(error, stackTrace, 'Map layer op failed (${_active.id})');
      } finally {
        // If the controller was replaced while this operation awaited native
        // code, it may have updated the layer's "mounted" bookkeeping after
        // the new style reset it. New-controller operations are serialised
        // behind this one, so reset once more here before they start.
        if (controllerEpoch != _controllerEpoch) {
          for (final layer in widget.layers) {
            layer.onStyleReset();
          }
        }
        _pendingMapOps--;
      }
    });
  }

  /// Hiding the on-screen layer from the picker's eye toggle must take it off
  /// screen — nothing else would. Route the exit through [_onLayerSelected] so
  /// the outgoing overlay is cleared exactly as a manual switch would. The
  /// picker keeps listing hidden layers, so the user can always come back.
  void _onVisibilityChanged() {
    final visibility = _visibility;
    if (visibility == null || !visibility.isHidden(_active.id)) return;
    final candidate = widget.layers.firstWhere(
      (layer) => !visibility.isHidden(layer.id),
      orElse: () => widget.layers.first,
    );
    if (candidate.id != _active.id) _onLayerSelected(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GsiOverlayScope(
        controller: _gsi,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final measured = constraints.biggest;
            if (measured.isFinite) _mapViewSize = measured;
            return _body(context);
          },
        ),
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
              includeTerrainInStyle: !widget.initialOsmEnabled,
              minZoomPreference: _active.mapMinZoom,
              maxZoomPreference: _gsi.enabled
                  ? gsiDisplayMaxZoom
                  : _active.mapMaxZoom,
              // The map tab owns this surface — pause native rendering when the
              // user is on another tab (indexedStack keeps it mounted).
              tabIndex: widget.tabIndex,
              recreateOnReturn: true,
              onMapInvalidated: _onMapInvalidated,
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
              onMapClick: (_, latLng) => _onMapClick(latLng),
              onMapIdle: () => _active.onMapIdle(),
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
          readyFrameId: isRaster ? active.readyVisibleFrameId : null,
        ),
      ),
    );
  }
}
