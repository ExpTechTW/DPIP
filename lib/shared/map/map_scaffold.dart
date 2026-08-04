import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/map_cache.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/map_timeline.dart';
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
  const MapScaffold({super.key, required this.layers, this.initialLayerId})
    : assert(layers.length > 0, 'MapScaffold needs at least one layer');

  /// The layers this surface offers; [initialLayerId] (or the first entry) is
  /// shown initially.
  final List<MapLayer> layers;

  /// Preferred overlay id (`MapLayer.id`) when the surface mounts. Unknown /
  /// missing → [layers].first.
  final String? initialLayerId;

  @override
  State<MapScaffold> createState() => _MapScaffoldState();
}

class _MapScaffoldState extends State<MapScaffold> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;

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
  int _cameraEpoch = 0;

  /// Basemap tile warm-up. Its own warmer so a layer's cancel can't abort it.
  MapTileWarmer? _basemapWarmer;

  /// Whether a frame-show op is already queued and hasn't started running yet.
  ///
  /// Timeline reports every crossed frame; settle mounts (~3 sources) are the
  /// expensive path. Coalesce so at most one op waits behind the running one.
  bool _showQueued = false;

  /// Finger down / fling in flight — raster layers skip cold mounts.
  bool _scrubbing = false;

  /// Whether a scrub reveal is running (see [_pumpScrub]).
  bool _scrubInFlight = false;

  /// The map view's own size, captured at layout — see [_applyFraming].
  Size? _mapViewSize;

  /// The geography the map is framed on, kept across layer switches so each
  /// layer re-frames the *same* place into its own visible band.
  LatLngBounds? _target;

  /// Measured height of the timeline panel (0 when the active layer has none).
  double _timelineHeight = 0;
  final GlobalKey _timelineKey = GlobalKey();

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
  }

  @override
  void dispose() {
    _basemapWarmer?.cancel();
    _handoff?.removeListener(_onHandoff);
    _stationHandoff?.removeListener(_onStationHandoff);
    super.dispose();
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
    _frameBounds(pending.bounds);
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
  void _frameBounds(LatLngBounds bounds) {
    _target = safeFitBounds(bounds);
    _applyFraming();
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
  void _applyFraming() {
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
    if (fit != null) {
      _controller?.moveCamera(CameraUpdate.newLatLngZoom(fit.target, fit.zoom));
    }
  }

  /// How much of the map's bottom the active layer's resting chrome hides: the
  /// layer's own declared share (a collapsed sheet, a status strip) plus the
  /// timeline, whose real height the scaffold measures because it owns it.
  double _bottomInset(Size size) =>
      size.height * _active.bottomChromeFraction + _timelineHeight;

  /// Measures the timeline panel after layout and re-frames if it changed, so a
  /// timeline layer frames into the band above the scrubber rather than behind it.
  void _measureTimeline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _timelineKey.currentContext?.findRenderObject() as RenderBox?;
      final height = (box != null && box.hasSize) ? box.size.height : 0.0;
      if ((height - _timelineHeight).abs() < 0.5) return;
      _timelineHeight = height;
      _applyFraming();
    });
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    _basemapWarmer ??= MapTileWarmer(context.read<MapTileCache?>());
    unawaited(const MapCache().setMaximumSize());
  }

  Future<void> _warmBasemap(MapLibreMapController controller) async {
    final warmer = _basemapWarmer;
    if (warmer == null) return;
    try {
      final bounds = await controller.getVisibleRegion();
      await warmer.warmViewportAbsolute(
        urlFor: (z, x, y) => _basemapTileUrl
            .replaceAll('{z}', '$z')
            .replaceAll('{x}', '$x')
            .replaceAll('{y}', '$y'),
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: controller.cameraPosition?.zoom ?? 8,
        maxZoom: 12,
        logLabel: 'basemap',
      );
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
          _selectedIndex = frames.isEmpty ? 0 : frames.length - 1; // newest
        });
        if (frames.isNotEmpty) {
          // Register the set, then reveal the newest (a layer adds tiles lazily).
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
    if (_showQueued) return;
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
    // Finger up: force a settle mount for the current index (may be cold).
    if (was && !scrubbing) _showSelected();
  }

  void _onFrameSelected(int index) {
    if (index < 0 || index >= _frames.length || index == _selectedIndex) return;
    // No setState: the map is updated imperatively via show(), so scrubbing
    // never rebuilds the (expensive) platform-view map. The timeline drives its
    // own display; _selectedIndex is just the source of truth for show().
    _selectedIndex = index;
    if (_scrubbing) {
      _pumpScrub();
      return;
    }
    _showSelected();
  }

  /// Drives scrub reveals **latest-wins**: at most one in flight, and whatever
  /// index the finger has reached by the time it finishes is what runs next.
  ///
  /// A fling crosses frames faster than a reveal completes. Firing one
  /// unawaited `show` per crossed frame piled up platform calls for frames
  /// already scrolled past — the map fell behind the finger and kept working
  /// after it stopped. Intermediate frames are *meant* to be dropped here; the
  /// settle ([_onScrubbing]) always renders the final position.
  void _pumpScrub() {
    if (_scrubInFlight) return;
    final controller = _controller;
    if (controller == null || _frames.isEmpty) return;
    _scrubInFlight = true;
    final index = _selectedIndex;
    _active
        .show(controller, _frames[index], scrubbing: true)
        .catchError((Object e, StackTrace st) {
          Log.handle(e, st, 'Map scrub reveal (${_active.id})');
        })
        .whenComplete(() {
          _scrubInFlight = false;
          // The finger moved on while that ran — chase it.
          if (_scrubbing && _selectedIndex != index) _pumpScrub();
        });
  }

  void _onLayerSelected(MapLayer layer) {
    if (layer.id == _active.id) return;
    final controller = _controller;
    final previous = _active;
    // Invalidate in-flight loads/renders of the previous layer.
    _generation++;
    // Baking AED into / out of the style JSON changes [BaseMap.styleString] and
    // triggers a MapLibre style reload. Calling render before that finishes
    // hits missing layer ids (dpm-aed-*). Defer to [_onStyleLoaded].
    final styleWillReload = previous.bakedAedTileUrl != layer.bakedAedTileUrl;
    setState(() {
      _active = layer;
      _frames = const [];
      _error = null;
      // The old layer's chrome is gone; the new one measures itself (a timeline
      // layer re-measures in build, a sheet layer declares its own share).
      _timelineHeight = 0;
      if (styleWillReload) _styleLoaded = false;
    });
    if (controller != null) _queue(() => previous.clear(controller));
    // Re-frame the same target into the new layer's band — switching to radar
    // after picking a township keeps the township framed, and each layer's
    // different chrome height is accounted for instead of reusing the old one.
    _applyFraming();
    if (!styleWillReload) _loadActive();
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
            onPointerDown: (_) => _active.onMapGestureStart(),
            onPointerUp: (_) {
              // Tap with no pan: camera idle won't re-fire — restore overlays.
              final c = _controller;
              if (c == null || !c.isCameraMoving) {
                _active.onMapGestureEnd();
                if (mounted) setState(() => _cameraEpoch++);
              }
            },
            onPointerCancel: (_) {
              _active.onMapGestureEnd();
              if (mounted) setState(() => _cameraEpoch++);
            },
            child: BaseMap(
              minZoomPreference: _active.mapMinZoom,
              maxZoomPreference: _active.mapMaxZoom,
              aedTileUrl: _active.bakedAedTileUrl,
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
              onMapClick: (_, latLng) => _onMapClick(latLng),
              onCameraIdle: () {
                _active.onMapGestureEnd();
                final controller = _controller;
                if (controller != null) {
                  unawaited(_active.onCameraIdle(controller));
                  unawaited(_warmBasemap(controller));
                }
                if (!mounted) return;
                setState(() => _cameraEpoch++);
              },
            ),
          ),
        ),
        // Screen-space Flutter overlays (e.g. typhoon forecast tips) — under
        // chrome/sheet so they don't steal taps; IgnorePointer keeps pan/zoom.
        Positioned.fill(
          child: IgnorePointer(
            child: KeyedSubtree(
              key: ValueKey<Object>('${_active.id}-$_cameraEpoch'),
              child: _active.buildMapOverlay(context),
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
                  // Non-typhoon layers return [SizedBox.shrink] — skip the gap.
                  final chrome = _active.buildTopTrailingChrome(context);
                  final hasChrome = chrome is! SizedBox;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasChrome) ...[
                        chrome,
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
              child: _frames.isNotEmpty
                  ? _timelinePanel(context)
                  : _error != null
                  ? _errorPanel(context)
                  : const SizedBox.shrink(),
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
        ),
      ),
    );
  }
}
