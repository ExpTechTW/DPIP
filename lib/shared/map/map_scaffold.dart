import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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

class _MapScaffoldState extends State<MapScaffold> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;

  late MapLayer _active = widget.layers.first;
  List<MapFrame> _frames = const [];
  int _selectedIndex = 0;
  Failure? _error;

  /// Bumped on every layer load; a load whose generation is stale is discarded.
  int _generation = 0;

  /// Serialises controller mutations so an add never races a remove.
  Future<void> _mapOps = Future<void>.value();

  void _onMapCreated(MapLibreMapController controller) =>
      _controller = controller;

  void _onStyleLoaded() {
    _styleLoaded = true;
    // Fires on the first load and again on every base-style reload (a theme /
    // dark-mode change), which wipes all runtime layers. Tell each layer to
    // forget its on-map state so the re-render re-adds instead of no-oping.
    for (final layer in widget.layers) {
      layer.onStyleReset();
    }
    _loadActive();
  }

  /// Fetches the active layer's frames and renders the newest.
  Future<void> _loadActive() async {
    if (_controller == null || !_styleLoaded) return;
    final gen = ++_generation;
    setState(() => _error = null);
    final result = await _active.frames();
    if (!mounted || gen != _generation) return;
    result.when(
      ok: (frames) {
        setState(() {
          _frames = frames;
          _selectedIndex = frames.isEmpty ? 0 : frames.length - 1; // newest
        });
        if (frames.isNotEmpty) {
          // Preload the whole set (tiles prefetch), then reveal the newest.
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
    // Read the target at execution time so a burst of scrub selections
    // coalesces to the latest frame instead of flooding the map with calls.
    _queue(() {
      if (_frames.isEmpty || !identical(layer, _active)) {
        return Future<void>.value();
      }
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
    });
    if (controller != null) _queue(() => previous.clear(controller));
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
      body: Stack(
        children: [
          Positioned.fill(
            child: BaseMap(
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MapLayerSwitcher(
                      layers: widget.layers,
                      active: _active,
                      onSelected: _onLayerSelected,
                    ),
                  ),
                ),
                if (_frames.isNotEmpty)
                  _timelinePanel(context)
                else if (_error != null)
                  _errorPanel(context),
              ],
            ),
          ),
        ],
      ),
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md + MediaQuery.paddingOf(context).bottom,
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          // Lift clear of the bottom nav (the shell body extends behind it).
          AppSpacing.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: MapTimeline(
          frames: _frames,
          selectedIndex: _selectedIndex,
          onSelected: _onFrameSelected,
        ),
      ),
    );
  }
}
