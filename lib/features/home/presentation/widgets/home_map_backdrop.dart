import 'dart:async';

import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/map_cache.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// Live map backdrop for the home page — a display-only [BaseMap] framed on the
/// selected township (outlined in purple) with the latest radar echo.
///
/// This replaces the earlier off-screen snapshot (which rendered the map to a
/// PNG via a native snapshotter): that path failed to decode radar tiles at
/// township zoom on device, so the map is now a real MapLibre map instead. It is
/// **non-interactive** — every gesture is disabled and the whole widget is
/// wrapped in [IgnorePointer] — so the page's own gestures pass straight
/// through: a tap opens the full map tab and a horizontal swipe switches area.
///
/// Everything on the map is driven from code via the controller: the selected
/// township is highlighted by filtering the vector `town` layer on its `CODE`,
/// the camera fits that township's bounds (nationwide fits the whole island),
/// always inset above the resting sheet, and a single raster layer shows the
/// newest radar frame (refreshed on home re-entry / app resume).
///
/// A base-style reload (theme change) wipes every runtime layer, so all controller
/// mutations run through one serial queue and are guarded by a style **epoch** and
/// per-concern **generations**; every add is idempotent (tolerant remove-then-add)
/// so a reload race or a partial failure re-syncs on the next apply instead of
/// wedging.
class HomeMapBackdrop extends StatefulWidget {
  const HomeMapBackdrop({super.key});

  @override
  State<HomeMapBackdrop> createState() => _HomeMapBackdropState();
}

class _HomeMapBackdropState extends State<HomeMapBackdrop>
    with WidgetsBindingObserver {
  static const String _selectedLineLayer = 'home-selected-line';
  static const String _radarSource = 'home-radar-src';
  static const String _radarLayer = 'home-radar-lyr';
  static const double _radarOpacity = 0.85;

  /// How far the selected township's bounds are pushed outward before fitting —
  /// a fraction of the box's span added to every side — so it frames with
  /// surrounding context instead of edge-to-edge. Fitting the (expanded) bounds
  /// keeps the zoom device-independent (MapLibre derives it from the box and the
  /// viewport). Raise for a looser frame.
  static const double _frameExpansion = 1;

  MapLibreMapController? _controller;
  bool _styleReady = false;
  RegionStore? _regions;
  HomeResetSignal? _resetSignal;
  MapCameraHandoff? _handoff;

  /// Serialises controller mutations so an add never races a remove/setFilter.
  Future<void> _ops = Future<void>.value();

  /// Bumped on every base-style (re)load — a reload wipes all runtime layers, so
  /// an op captured under an older epoch is dropped and the new style re-adds.
  int _styleEpoch = 0;

  /// Bumped per selection/radar apply so a superseded apply (its async work
  /// resolved late) is dropped instead of landing stale.
  int _selectionGen = 0;
  int _radarGen = 0;

  /// The (code, epoch) last applied — used to skip re-applying an unchanged
  /// selection (e.g. an unrelated GPS-driven RegionStore notification).
  String? _appliedCode;
  int _appliedCodeEpoch = -1;

  /// The (frame, epoch) of the radar echo on the map — used to skip a redundant
  /// re-render of the same frame.
  String? _radarFrameOnMap;
  int _radarFrameEpoch = -1;

  /// The map view's own size, captured at layout. The camera fit must be
  /// computed against **this**, not `MediaQuery` — MediaQuery describes the whole
  /// screen, so on any device whose map area differs from it (system chrome, a
  /// different aspect ratio) the derived zoom drifts and the framing is wrong by
  /// a device-dependent amount. Null until the first layout; callers fall back to
  /// MediaQuery for that one frame.
  Size? _mapViewSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final regions = context.read<RegionStore>();
    if (regions != _regions) {
      _regions?.removeListener(_onSelectionChanged);
      _regions = regions..addListener(_onSelectionChanged);
    }
    final reset = context.read<HomeResetSignal>();
    if (reset != _resetSignal) {
      _resetSignal?.removeListener(_refreshRadar);
      _resetSignal = reset..addListener(_refreshRadar);
    }
    _handoff = context.read<MapCameraHandoff>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshRadar();
  }

  void _onSelectionChanged() => _applySelection();

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    unawaited(const MapCache().setMaximumSize(150 * 1024 * 1024));
  }

  void _onStyleLoaded() {
    _styleReady = true;
    // A base-style (re)load dropped every runtime layer. Bump the epoch so any
    // in-flight op is discarded and the (epoch-mismatched) guards below force a
    // fresh re-add of the selection + radar.
    _styleEpoch++;
    _applySelection();
    _refreshRadar();
  }

  /// The selected township code, or null for the nationwide (whole-island) view.
  String? get _selectedCode => switch (_regions?.selected) {
    SavedArea(:final code) => code,
    CurrentArea(:final code) => code,
    _ => null,
  };

  /// Frames the map on the selected township and highlights it — or fits the
  /// whole island for the nationwide view. Skips unchanged selections.
  Future<void> _applySelection() async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    // Read context-bound values before any await.
    final size = _mapViewSize ?? MediaQuery.sizeOf(context);
    // The map fills the page, but the region bar is layered over its top and the
    // sheet over its bottom, so the band actually visible is shorter at both
    // ends. Frame into that band, not the whole map.
    final topInset = MediaQuery.paddingOf(context).top + RegionBar.height;
    final boundariesFuture = context.read<Future<TownBoundaries>>();
    final code = _selectedCode;
    final styleEpoch = _styleEpoch;
    // Nothing changed since the last apply (an unrelated RegionStore notify) —
    // don't re-add layers or re-run the camera.
    if (code == _appliedCode && styleEpoch == _appliedCodeEpoch) return;
    final townCode = code == null ? null : int.tryParse(code);
    final gen = ++_selectionGen;

    List<double>? bounds;
    if (code != null) {
      final boundaries = await boundariesFuture;
      if (!mounted || gen != _selectionGen || styleEpoch != _styleEpoch) return;
      bounds = boundaries.boundsFor(code);
    }

    final filter = _filterFor(townCode);
    // Normalise the fit box: a degenerate/non-finite township box would make
    // MapLibre's native camera fit abort the app (see camera_fit.dart).
    final box = safeFitBounds(_latLngBounds(bounds));
    if (box == null) return;
    // Hand the framed geography to the map tab; it fits the same box into its
    // own visible band (different chrome, so a different camera).
    // (An earlier version projected the on-screen band via controller.toLatLng,
    // but the plugin's screen coordinates didn't line up with MediaQuery's
    // logical size and mis-framed the map onto the strait, so the simple box is
    // used instead.)
    _handoff?.homeBounds = box;
    final bottomInset = size.height * HomeSheetExtent.rest;
    _queue(() async {
      if (!mounted || gen != _selectionGen || styleEpoch != _styleEpoch) return;
      await _addSelectedLayers(controller, filter);
      // Frame the box in the band above the resting sheet — computed in Dart
      // (boundsFitCamera) and applied as a plain centre+zoom, so a degenerate or
      // not-yet-laid-out viewport can't abort the app the way MapLibre's native
      // bounds-fit (newLatLngBounds) does.
      final fit = boundsFitCamera(
        box,
        viewport: size,
        topInset: topInset,
        bottomInset: bottomInset,
      );
      if (fit != null) {
        await controller.moveCamera(
          CameraUpdate.newLatLngZoom(fit.target, fit.zoom),
        );
      }
      _appliedCode = code;
      _appliedCodeEpoch = styleEpoch;
    });
  }

  /// (Re)adds the purple selection outline on the vector `town` layer (filtered
  /// by `CODE`), left on top so it sits above the radar/borders. Outline only —
  /// no fill, so the township's radar/base stays visible inside it. Idempotent:
  /// any prior copy is removed first, so a reload race or partial failure can't
  /// wedge the highlight.
  Future<void> _addSelectedLayers(
    MapLibreMapController controller,
    List<Object> filter,
  ) async {
    await _removeLayerQuietly(controller, _selectedLineLayer);
    await controller.addLineLayer(
      'exptech',
      _selectedLineLayer,
      const LineLayerProperties(lineColor: selectedColor, lineWidth: 2.5),
      sourceLayer: 'town',
      filter: filter,
      enableInteraction: false,
    );
  }

  /// Fetches the newest radar frame and swaps it in (below the borders). A
  /// failed fetch, an unchanged frame, or a superseded refresh is a no-op, so
  /// the current echo stays. The swap is idempotent (tolerant remove-then-add)
  /// so a partial failure can't strand or duplicate the source.
  Future<void> _refreshRadar() async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    final radar = context.read<RadarRepository>();
    final gen = ++_radarGen;
    final styleEpoch = _styleEpoch;
    final frames = (await radar.frames()).valueOrNull;
    if (!mounted || gen != _radarGen || styleEpoch != _styleEpoch) return;
    if (frames == null || frames.isEmpty) return;
    final latest = frames.first; // newest first
    if (latest == _radarFrameOnMap && styleEpoch == _radarFrameEpoch) return;

    _queue(() async {
      if (!mounted || gen != _radarGen || styleEpoch != _styleEpoch) return;
      await _removeLayerQuietly(controller, _radarLayer);
      await _removeSourceQuietly(controller, _radarSource);
      await controller.addSource(
        _radarSource,
        RasterSourceProperties(tiles: [radar.tileUrl(latest)], tileSize: 256),
      );
      await controller.addRasterLayer(
        _radarSource,
        _radarLayer,
        const RasterLayerProperties(rasterOpacity: _radarOpacity),
        belowLayerId: outlineLayerId,
      );
      _radarFrameOnMap = latest;
      _radarFrameEpoch = styleEpoch;
    });
  }

  /// Removes [layerId] if present, tolerating a "not found" — so re-adding after
  /// a style reload or a partial failure is idempotent.
  Future<void> _removeLayerQuietly(
    MapLibreMapController controller,
    String layerId,
  ) async {
    try {
      await controller.removeLayer(layerId);
    } catch (_) {
      // Expected when the layer isn't on the map (fresh style / first add).
    }
  }

  Future<void> _removeSourceQuietly(
    MapLibreMapController controller,
    String sourceId,
  ) async {
    try {
      await controller.removeSource(sourceId);
    } catch (_) {
      // Expected when the source isn't on the map (fresh style / first add).
    }
  }

  /// A `CODE` equality filter — the impossible `-1` matches nothing, hiding the
  /// selection layers for the nationwide view.
  List<Object> _filterFor(int? code) => <Object>[
    '==',
    <Object>['get', 'CODE'],
    code ?? -1,
  ];

  /// The bounds to frame — the selected township (pushed outward by
  /// [_frameExpansion] for breathing room), or the whole island (already
  /// framed with margin) for the nationwide view.
  LatLngBounds _latLngBounds(List<double>? bounds) {
    if (bounds == null) return BaseMap.taiwanBounds;
    final minLng = bounds[0], minLat = bounds[1], maxLng = bounds[2];
    final maxLat = bounds[3];
    final dLng = (maxLng - minLng) * _frameExpansion;
    final dLat = (maxLat - minLat) * _frameExpansion;
    return LatLngBounds(
      southwest: LatLng(minLat - dLat, minLng - dLng),
      northeast: LatLng(maxLat + dLat, maxLng + dLng),
    );
  }

  /// Appends [op] to the serial controller-op chain, logging any failure — a
  /// failed map op degrades the backdrop, it never throws into the tree.
  void _queue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((Object e, StackTrace st) {
      Log.handle(e, st, 'Home map op failed');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _regions?.removeListener(_onSelectionChanged);
    _resetSignal?.removeListener(_refreshRadar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display-only: gestures are disabled on the map and the whole subtree is
    // ignored for hit-testing, so the page's tap (open map) and horizontal swipe
    // (switch area) pass straight through.
    return IgnorePointer(
      // LayoutBuilder measures the map itself, so the camera fit is derived from
      // the surface the map actually occupies rather than the whole screen. A
      // size change (rotation, split view, a different device) re-frames.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final measured = constraints.biggest;
          if (measured != _mapViewSize && measured.isFinite) {
            _mapViewSize = measured;
            // Re-frame once the new size is laid out. Bypasses the
            // unchanged-selection guard, which only tracks the code, not the size.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _appliedCode = null;
              _applySelection();
            });
          }
          return BaseMap(
            interactive: false,
            onMapCreated: _onMapCreated,
            onStyleLoaded: _onStyleLoaded,
          );
        },
      ),
    );
  }
}
