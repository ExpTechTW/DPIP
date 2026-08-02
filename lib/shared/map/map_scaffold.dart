import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/map_cache.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// Ambient tile-cache ceiling for the live map — well above MapLibre's ~50 MB
/// native default so a week of small WebP radar frames (plus base tiles) stays
/// cached and scrubbing the timeline re-fetches far less.
const int _ambientCacheBytes = 128 * 1024 * 1024;

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
  const MapScaffold({super.key, required this.layers})
    : assert(layers.length > 0, 'MapScaffold needs at least one layer');

  /// The layers this surface offers; the first is shown initially.
  final List<MapLayer> layers;

  @override
  State<MapScaffold> createState() => _MapScaffoldState();
}

class _MapScaffoldState extends State<MapScaffold> with WidgetsBindingObserver {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;

  /// Whether the initial framing has run. Only on first load — a reload (theme
  /// change) keeps whatever the user has panned/zoomed to.
  bool _framed = false;

  /// Hand-off of a target framing from whoever opened the map (the Home backdrop
  /// tap, or the nav bar). A one-shot request per open; null keeps the view.
  MapCameraHandoff? _handoff;

  late MapLayer _active = widget.layers.first;
  List<MapFrame> _frames = const [];
  int _selectedIndex = 0;
  Failure? _error;

  /// Bumped on every layer load; a load whose generation is stale is discarded.
  int _generation = 0;

  /// Serialises controller mutations so an add never races a remove.
  Future<void> _mapOps = Future<void>.value();

  /// Whether tiles have been cached since the last clear — so backgrounding only
  /// clears the shared cache when there's actually something to clear.
  bool _cacheDirty = false;

  /// Whether a frame-show op is already queued and hasn't started running yet.
  ///
  /// The timeline reports *every* frame the scrubber crosses (so the map
  /// animates during the drag), and each show does real platform work — add /
  /// remove raster sources and layers, then load their tiles. Queueing one op
  /// per reported frame let a fast scrub build a backlog of renders for frames
  /// the user had already passed, so releasing the scrubber stalled until that
  /// whole backlog drained. This flag coalesces the burst instead: while an op
  /// is pending, further selections only move [_selectedIndex], and the pending
  /// op renders whatever is current *when it runs*. At most one op is queued
  /// behind the running one, so the map still animates through the scrub but a
  /// release always lands within one render instead of dozens.
  bool _showQueued = false;

  /// The map view's own size, captured at layout — see [_applyFraming].
  Size? _mapViewSize;

  /// The geography the map is framed on, kept across layer switches so each
  /// layer re-frames the *same* place into its own visible band.
  LatLngBounds? _target;

  /// Measured height of the timeline panel (0 when the active layer has none).
  double _timelineHeight = 0;
  final GlobalKey _timelineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _handoff?.removeListener(_onHandoff);
    WidgetsBinding.instance.removeObserver(this);
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
      final bounds = _handoff?.takePending();
      if (bounds != null) _frameBounds(bounds);
    });
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Scrubbing a layer caches every frame's tiles in MapLibre's *shared*
    // on-disk cache (removeSource doesn't evict them). That cache also backs the
    // home page's off-screen map snapshot, and a bloated one stops its overlay
    // from rendering. Clear it as the map backgrounds so the next launch's
    // snapshot starts clean. Harmless: live tiles just refetch on resume.
    if (state == AppLifecycleState.paused &&
        _controller != null &&
        _cacheDirty) {
      _cacheDirty = false;
      _controller!.clearAmbientCache().catchError((Object error) {
        Log.warning('Failed to clear map ambient cache: $error');
      });
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    // Raise the shared ambient-cache ceiling (MapLibre's default is only ~50 MB)
    // now that the map exists so MapLibre is initialised on both platforms. The
    // cache stays bounded (LRU) and is still cleared on background so the home
    // snapshot starts clean.
    const MapCache().setMaximumSize(_ambientCacheBytes);
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
      _frameBounds(_handoff?.takePending() ?? BaseMap.taiwanBounds);
    }
    _loadActive();
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
    _cacheDirty = true; // showing a frame caches its tiles
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
      // Read the target at execution time so the render is the newest frame, not
      // the one that was current when this op was queued.
      return layer.show(controller, _frames[_selectedIndex]);
    });
  }

  void _onFrameSelected(int index) {
    if (index < 0 || index >= _frames.length || index == _selectedIndex) return;
    // No setState: the map is updated imperatively via show(), so scrubbing
    // never rebuilds the (expensive) platform-view map. The timeline drives its
    // own display; _selectedIndex is just the source of truth for show().
    _selectedIndex = index;
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
    // Re-frame the same target into the new layer's band — switching to radar
    // after picking a township keeps the township framed, and each layer's
    // different chrome height is accounted for instead of reusing the old one.
    _applyFraming();
    _loadActive();
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
          child: BaseMap(
            onMapCreated: _onMapCreated,
            onStyleLoaded: _onStyleLoaded,
            onMapClick: (_, latLng) => _onMapClick(latLng),
          ),
        ),
        // A sheet layer's own collapsible detail sheet (empty until a tap).
        if (!_active.usesTimeline)
          Positioned.fill(child: _active.buildSheet(context)),
        // A timeline layer's bottom scrubber / error strip. Keyed so its real
        // height can be measured and subtracted when framing.
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
        // Layer switcher — top-right, always above the sheet / timeline.
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: MapLayerSwitcher(
                layers: widget.layers,
                active: _active,
                onSelected: _onLayerSelected,
              ),
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
    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      borderRadius: AppRadius.topSheet,
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
    );
  }

  Widget _timelinePanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      borderRadius: AppRadius.topSheet,
      child: Padding(
        // The bottom-nav clearance is the SafeArea wrapper's job (see build);
        // adding MediaQuery's bottom inset here too made the panel very tall.
        padding: const EdgeInsets.all(AppSpacing.md),
        child: MapTimeline(
          frames: _frames,
          selectedIndex: _selectedIndex,
          onSelected: _onFrameSelected,
        ),
      ),
    );
  }
}
