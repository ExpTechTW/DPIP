/// Disaster-prevention map layer — MVT overlays (AED / restroom / shelter)
/// added at runtime, with a tune menu to toggle each sub-layer; tap → sheet.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/widgets/disaster_map_overlay_menu.dart';
import 'package:dpip/features/map/presentation/widgets/dpm_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Sheet-driven [MapLayer] for the disaster-prevention map (DPM).
///
/// Switcher entry is 「防災地圖」; [DisasterMapOverlayMenu] toggles the
/// sub-layers (AED / restroom / shelter). Each sub-layer's MVT is added with
/// [MapLibreMapController.addSource] / [addSymbolLayer] on [render] (baking
/// into the base style JSON was a silent no-op / race on style reload) — the
/// marker is a colour-badged icon baked to a PNG via [_renderMarker], one per
/// sub-layer (restroom: one per `type` code, see [restroomTypeColors]),
/// registered with [MapLibreMapController.addImage]. A tap that
/// hits several overlapping markers zooms in to spread them apart instead of
/// guessing which one was meant (see [onMapTap]); detail on a single-hit tap
/// comes from [DisasterMapRepository].
class DisasterMapLayer with MapLayerDefaults implements MapLayer {
  DisasterMapLayer(this._repository);

  final DisasterMapRepository _repository;

  MapLibreMapController? _controller;
  bool _styleReady = false;
  Future<void> _ops = Future<void>.value();

  /// Sub-layers whose filter [DpmFilter.values] listeners are attached
  /// (`ValueNotifier.hasListeners` is protected, so tracked here instead).
  final Set<DpmSubLayerBase> _filterListening = {};

  /// AED points — on by default.
  final DpmSubLayer<AedDetail> aed = DpmSubLayer<AedDetail>(
    id: 'aed',
    sourceId: dpmAedSourceId,
    pointsLayerId: dpmAedPointsLayerId,
    tileLayer: 'aed',
    color: _aedColor,
    icon: Icons.medical_services_outlined,
  );

  /// Restroom points — on by default.
  final DpmSubLayer<RestroomDetail> restroom = DpmSubLayer<RestroomDetail>(
    id: 'restroom',
    sourceId: dpmRestroomSourceId,
    pointsLayerId: dpmRestroomPointsLayerId,
    tileLayer: 'restroom',
    color: _restroomColor,
    icon: Icons.wc_outlined,
    // Two filter dimensions — venue (`type2`) and toilet kind (`type`) —
    // both apply, i.e. a point must satisfy both chip rows to render.
    filters: {'type2': DpmFilter('type2'), 'type': DpmFilter('type')},
  );

  /// Shelter points — on by default.
  final DpmSubLayer<ShelterDetail> shelter = DpmSubLayer<ShelterDetail>(
    id: 'shelter',
    sourceId: dpmShelterSourceId,
    pointsLayerId: dpmShelterPointsLayerId,
    tileLayer: 'shelter',
    color: _shelterColor,
    icon: Icons.home_work_outlined,
    filters: {'category': DpmFilter('category')},
  );

  /// All switchable sub-layers, in draw order (later on top).
  List<DpmSubLayerBase> get subLayers => [aed, restroom, shelter];

  // The badge palette, colour-vision corrected at the definition. Getters
  // rather than `static const`, because the transform is not a compile-time
  // constant. Every marker on this layer is *baked by us* from these hexes
  // ([_renderMarker]) — nothing here is server-rendered raster — so they
  // correct like the rest of the app. The legend reads the very same strings
  // (`sub.color` / this map) through `colorFromHexRgb`, which is why the badge
  // and its key can't drift: they are one already-transformed value converted,
  // not two transforms.
  //
  // Read once, when the sub-layers below are constructed: the marker PNGs are
  // baked and cached from them, so a setting change lands with the layer that
  // rebuilds them, not mid-session.
  static String get _aedColor => '#e74c3c'.vision;
  static String get _restroomColor => '#2d9cdb'.vision;
  static String get _shelterColor => '#f2994a'.vision;

  /// Restroom marker colours per `type` code — six distinct hues so a dense
  /// single kind can't drown out the other sub-layers' markers (AED red /
  /// shelter orange); unknown codes (0 / 7) fall back to [_restroomColor].
  ///
  /// Six hues that have to stay *told apart*, which is the whole point of the
  /// correction — so each is transformed at its definition here.
  static Map<int, String> get restroomTypeColors => {
    1: '#ec4899'.vision,
    2: '#3b82f6'.vision,
    3: '#64748b'.vision,
    4: '#22c55e'.vision,
    5: '#a855f7'.vision,
    6: '#06b6d4'.vision,
  };

  /// Finger-sized hit box around a tap, in logical pixels.
  static const double _tapSlop = 44;

  /// Zoom-in step when a tap hits several overlapping markers, so the next
  /// tap has a better chance of landing on just one.
  static const double _clusterZoomStep = 3;

  /// Markers render from the DPM map floor — the default Taiwan framing
  /// (~zoom 7–8) already shows them, like the old circle overlays. Nationwide
  /// there are thousands of AED / restroom / shelter points, so the icon is
  /// scaled small at overview zoom and MapLibre's symbol collision engine
  /// declutters dense areas itself (same pattern as Apple/Google Maps POI
  /// pins — a hidden marker isn't tappable until it has room to render;
  /// [onMapTap] still handles the rarer case of a few markers touching).
  static const double _pointsMinZoom = 4;

  /// Rendered marker PNGs, keyed by image id, cached — a badge never changes.
  final Map<String, Uint8List> _markerImages = {};

  static String _markerImageId(String subId, {int? type}) =>
      type == null ? 'dpm-marker-$subId' : 'dpm-marker-$subId-$type';

  /// Localized label for a DPM [id] (`aed` / `restroom` / `shelter`).
  static String layerLabel(AppLocalizations l10n, String id) => switch (id) {
    'aed' => l10n.mapLayerAed,
    'restroom' => l10n.mapLayerRestroom,
    'shelter' => l10n.mapLayerShelter,
    _ => id,
  };

  /// Localized overlay-menu tooltip for a DPM [id].
  static String layerTooltip(AppLocalizations l10n, String id) => switch (id) {
    'aed' => l10n.disasterMapOverlayAedTooltip,
    'restroom' => l10n.disasterMapOverlayRestroomTooltip,
    'shelter' => l10n.disasterMapOverlayShelterTooltip,
    _ => '',
  };

  /// Localized restroom toilet-kind label for a `type` code.
  static String restroomTypeLabel(AppLocalizations l10n, int type) =>
      switch (type) {
        1 => l10n.restroomTypeFemale,
        2 => l10n.restroomTypeMale,
        3 => l10n.restroomTypeMixed,
        4 => l10n.restroomTypeAccessible,
        5 => l10n.restroomTypeGenderNeutral,
        6 => l10n.restroomTypeFamily,
        7 => l10n.restroomTypeUnspecified,
        _ => '',
      };

  @override
  String get id => 'dpm';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerDisasterMap;

  @override
  IconData get icon => Icons.health_and_safety_outlined;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => DpmSheet.peekExtent;

  @override
  double get mapMaxZoom => 16;

  /// DPM MVT is added at runtime — never bake into the base style JSON.

  /// Toggle a sub-layer; clears its selection when turned off and stops
  /// prefetching when no sub-layer remains visible.
  void setSubLayerVisible(DpmSubLayerBase sub, bool value) {
    if (sub.visible.value == value) return;
    sub.visible.value = value;
    if (!value) {
      sub.clearSelection();
      if (!subLayers.any((s) => s.visible.value)) {
        _repository.cancelTilePrefetch();
      }
    } else {
      final c = _controller;
      if (c != null) unawaited(_prefetchViewport(c));
    }
    _applyOverlayVisibility();
  }

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _ensureSubLayers(controller);
    _styleReady = true;
    Log.info('DPM runtime tiles: ${_repository.tileUrl('aed')}');
    await _applyOverlayVisibilityAsync(controller);
    await _applyOverlayFiltersAsync(controller);
    for (final sub in subLayers) {
      if (_filterListening.contains(sub)) continue;
      _filterListening.add(sub);
      for (final filter in sub.filters.values) {
        filter.values.addListener(_onFilterChanged);
      }
    }
    unawaited(_prefetchViewport(controller));
  }

  /// A category filter changed — re-apply it and drop any selection that may
  /// no longer be rendered.
  void _onFilterChanged() {
    _applyOverlayFilters();
    for (final sub in subLayers) {
      if (sub.selectionId.value != null) sub.clearSelection();
    }
  }

  /// MapLibre filter expression for [sub] from its [DpmSubLayerBase.filters];
  /// `null` when the sub-layer isn't filterable (AED).
  ///
  /// Nothing selected = no constraint, so the previous filter (if any) must
  /// be replaced by one matching every feature — the impossible value
  /// (`type2 = -1` / `category = ''`), negated. Every comparison is
  /// **binary** (two operands only): MapLibre's iOS predicate conversion
  /// crashes on any expression with more than three elements —
  /// `['in', key, v1, v2, ...]` is misparsed as a collator and the value `v2`
  /// (an NSNumber) gets a `.count` message it doesn't implement
  /// (`doesNotRecognizeSelector` → SIGABRT). Multi-value membership is instead
  /// expressed as an `any` of binary `==` / `in` comparisons, and the two
  /// restroom dimensions (`type2` × `type`) combine under a binary `all`.
  List<Object>? _filterExpression(DpmSubLayerBase sub) {
    final filters = sub.filters.values.toList();
    if (filters.isEmpty) return null;
    final isShelter = identical(sub, shelter);
    final expressions = <Object>[];
    for (final filter in filters) {
      final active = filter.values.value;
      if (active.isEmpty) continue;
      final key = <Object>['get', filter.property];
      if (isShelter) {
        // `category` is a JSON-array string — membership, not equality.
        expressions.add(<Object>[
          'any',
          for (final value in active) <Object>['in', value, key],
        ]);
      } else {
        expressions.add(<Object>[
          'any',
          for (final value in active) <Object>['==', key, value],
        ]);
      }
    }
    if (expressions.isEmpty) {
      // No chip selected — render everything (see doc above).
      return <Object>[
        '!=',
        <Object>['get', isShelter ? 'category' : 'type2'],
        isShelter ? '' : -1,
      ];
    }
    if (expressions.length == 1) return expressions.single as List<Object>;
    return <Object>['all', ...expressions];
  }

  void _applyOverlayFilters() {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    _queue(() => _applyOverlayFiltersAsync(controller));
  }

  Future<void> _applyOverlayFiltersAsync(
    MapLibreMapController controller,
  ) async {
    for (final sub in subLayers) {
      final expression = _filterExpression(sub);
      if (expression == null) continue;
      try {
        await controller.setLayerFilter(
          sub.pointsLayerId,
          jsonEncode(expression),
        );
      } catch (error, stackTrace) {
        Log.handle(
          error,
          stackTrace,
          'DPM setLayerFilter(${sub.pointsLayerId})',
        );
      }
    }
  }

  Future<void> _ensureSubLayers(MapLibreMapController controller) async {
    final ids = await controller.getLayerIds();
    final idSet = {for (final id in ids) id.toString()};
    for (final sub in subLayers) {
      if (idSet.contains(sub.pointsLayerId)) continue;
      final tileUrl = _repository.tileUrl(sub.id);
      try {
        await controller.removeSource(sub.sourceId);
      } catch (_) {
        // Source absent — fine.
      }

      await controller.addSource(
        sub.sourceId,
        VectorSourceProperties(tiles: [tileUrl], minzoom: 0, maxzoom: 16),
      );

      final markerId = _markerImageId(sub.id);
      final bytes = _markerImages[markerId] ??= await _renderMarker(
        sub.icon,
        sub.color,
      );
      await controller.addImage(markerId, bytes);
      if (identical(sub, restroom)) {
        // One badge per restroom `type` code — see [restroomTypeColors].
        for (final entry in restroomTypeColors.entries) {
          final typeId = _markerImageId(sub.id, type: entry.key);
          final typeBytes = _markerImages[typeId] ??= await _renderMarker(
            sub.icon,
            entry.value,
          );
          await controller.addImage(typeId, typeBytes);
        }
      }

      // One layer, no filter: the tileset is downsampled server-side, so every
      // feature is real and they are all drawn the same way. Overlap is left
      // at MapLibre's default (false) so its collision engine declutters
      // dense areas itself — a hidden marker isn't meant to be tappable until
      // it has room to render; [onMapTap] still handles the rarer case of a
      // few markers still touching under one tap.
      await controller.addSymbolLayer(
        sub.sourceId,
        sub.pointsLayerId,
        SymbolLayerProperties(
          iconImage: identical(sub, restroom)
              ? <Object>[
                  'match',
                  <Object>['get', 'type'],
                  for (final entry in restroomTypeColors.entries) ...[
                    entry.key,
                    _markerImageId(sub.id, type: entry.key),
                  ],
                  markerId,
                ]
              : markerId,
          iconSize: <Object>[
            'interpolate',
            <Object>['linear'],
            <Object>['zoom'],
            _pointsMinZoom,
            0.45,
            8,
            0.52,
            12,
            0.60,
            mapMaxZoom,
            0.68,
          ],
        ),
        sourceLayer: sub.tileLayer,
        minzoom: _pointsMinZoom,
        // **false on purpose.** An interactive layer makes the plugin fire
        // `feature#onTap` instead of `map#onMapClick` (unless the map opts into
        // featureTapsTriggersMapClick), and nothing in this app listens to
        // feature taps — so tapping a marker went nowhere while tapping empty
        // sea still reached onMapTap. Every other layer here is false too.
        enableInteraction: false,
      );
    }
  }

  /// Bakes a colour-filled circle badge with a white icon glyph into a PNG —
  /// MapLibre symbol icons need a raster image, not a widget, and colouring
  /// only the glyph (leaving the badge fill per sub-layer) needs two-tone
  /// paint that a single `sdf` recolour can't do, so the whole marker (badge +
  /// glyph) is drawn once per sub-layer and cached in [_markerImages].
  Future<Uint8List> _renderMarker(IconData icon, String colorHex) async {
    const size = 96.0;
    const center = Offset(size / 2, size / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fill = Paint()
      ..color = colorFromHexRgb(colorHex) ?? Colors.grey
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.42, fill);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05;
    canvas.drawCircle(center, size * 0.42, stroke);

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.46,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _removeSubLayers(MapLibreMapController controller) async {
    for (final sub in subLayers) {
      try {
        await controller.removeLayer(sub.pointsLayerId);
      } catch (_) {}
    }
    for (final sub in subLayers) {
      try {
        await controller.removeSource(sub.sourceId);
      } catch (_) {}
    }
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (!_styleReady) return;
    final visible = subLayers.where((s) => s.visible.value).toList();
    if (visible.isEmpty) return;
    final screen = await controller.toScreenLocation(latLng);
    // Query a box, not the exact pixel: the markers are ~40 pt wide, so an
    // exact hit-test asks for that when a fingertip is nearer 44. Query per
    // sub-layer — a rendered feature's JSON carries no reliable style-layer
    // key on every platform (iOS's geoJSONDictionary has none), so the layer
    // comes from the query, not the feature dict.
    const slop = _tapSlop;
    final rect = Rect.fromCenter(
      center: Offset(screen.x.toDouble(), screen.y.toDouble()),
      width: slop,
      height: slop,
    );
    // Distinct (sub-layer, feature id) hits — a tap can return the same point
    // twice at a tile boundary, and different sub-layers may legitimately
    // overlap (an AED next to a shelter).
    final seen = <String>{};
    final distinct = <(DpmSubLayerBase, dynamic)>[];
    for (final sub in visible) {
      final points = await controller.queryRenderedFeaturesInRect(rect, [
        sub.pointsLayerId,
      ], null);
      for (final feature in points) {
        final id = _featureId(feature);
        if (id == null) continue;
        if (seen.add('${sub.id}:$id')) distinct.add((sub, feature));
      }
    }
    if (distinct.isEmpty) return;
    if (distinct.length == 1) {
      await _selectFeature(distinct.single.$1, distinct.single.$2);
      return;
    }
    // Several markers overlap under the fingertip — zoom in to spread them
    // apart on the map instead of guessing which one was meant; the user taps
    // again once they've separated.
    final zoom = controller.cameraPosition?.zoom ?? 10;
    if (zoom >= mapMaxZoom - 0.01) {
      await _selectFeature(distinct.first.$1, distinct.first.$2);
      return;
    }
    final nextZoom = zoom + _clusterZoomStep > mapMaxZoom
        ? mapMaxZoom
        : zoom + _clusterZoomStep;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, nextZoom),
    );
  }

  Future<void> _selectFeature(DpmSubLayerBase sub, dynamic feature) async {
    final id = _featureId(feature);
    if (id == null) return;
    for (final s in subLayers) {
      if (s != sub) s.clearSelection();
    }
    final props = _props(feature);
    sub.selectionId.value = id;
    sub.previewName.value = props['name']?.toString();
    sub.previewPlace.value = _previewPlace(sub, props);
    sub.setDetail(null);
    sub.selectionRevision.value++;
    final result = await _fetchDetail(sub, id);
    if (sub.selectionId.value != id) return;
    result.when(ok: (detail) => sub.setDetail(detail), err: (_) {});
  }

  /// Internal tile feature id: top-level feature id first (restroom puts no
  /// `id` in its properties), falling back to the property map.
  static int? _featureId(dynamic feature) {
    if (feature is Map) {
      final topLevel = _asInt(feature['id']);
      if (topLevel != null) return topLevel;
      final p = feature['properties'];
      if (p is Map) return _asInt(p['id']);
    }
    return null;
  }

  static String? _previewPlace(
    DpmSubLayerBase sub,
    Map<String, dynamic> props,
  ) {
    if (sub.id == 'aed') return props['place']?.toString();
    if (sub.id == 'restroom') return props['address']?.toString();
    return null;
  }

  Future<Result<Object?>> _fetchDetail(DpmSubLayerBase sub, int id) {
    if (sub == aed) return _repository.aedDetail(id);
    if (sub == restroom) return _repository.restroomDetail(id);
    return _repository.shelterDetail(id);
  }

  static Map<String, dynamic> _props(dynamic feature) {
    if (feature is Map) {
      final p = feature['properties'];
      if (p is Map) return Map<String, dynamic>.from(p);
    }
    return const {};
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _applyOverlayVisibility() {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    _queue(() => _applyOverlayVisibilityAsync(controller));
  }

  Future<void> _applyOverlayVisibilityAsync(
    MapLibreMapController controller,
  ) async {
    for (final sub in subLayers) {
      final visible = sub.visible.value;
      try {
        await controller.setLayerVisibility(sub.pointsLayerId, visible);
      } catch (error, stackTrace) {
        Log.handle(
          error,
          stackTrace,
          'DPM setLayerVisibility(${sub.pointsLayerId} → $visible)',
        );
      }
    }
  }

  void _queue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((_) {});
  }

  @override
  Widget buildSheet(BuildContext context) =>
      DpmSheet(aed: aed, restroom: restroom, shelter: shelter, onClose: close);

  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          for (final sub in subLayers)
            if (identical(sub, restroom))
              for (final entry in restroomTypeColors.entries)
                SymbolLegendItem(
                  swatch: _DpmSwatch(
                    color: colorFromHexRgb(entry.value) ?? Colors.grey,
                    icon: sub.icon,
                    size: 16,
                  ),
                  label: restroomTypeLabel(l10n, entry.key),
                )
            else
              SymbolLegendItem(
                swatch: _DpmSwatch(
                  color: colorFromHexRgb(sub.color) ?? Colors.grey,
                  icon: sub.icon,
                  size: 16,
                ),
                label: layerLabel(l10n, sub.id),
              ),
        ],
      ),
    );
  }

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => DisasterMapOverlayMenu(
    layer: this,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) =>
      _prefetchViewport(controller);

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) =>
      _prefetchViewport(controller);

  Future<void> _prefetchViewport(MapLibreMapController controller) async {
    final visible = subLayers.where((s) => s.visible.value).toList();
    if (!_styleReady || visible.isEmpty) return;
    try {
      final bounds = await controller.getVisibleRegion();
      final zoom = controller.cameraPosition?.zoom ?? 10;
      for (final sub in visible) {
        await _repository.prefetchTiles(
          layer: sub.id,
          south: bounds.southwest.latitude,
          west: bounds.southwest.longitude,
          north: bounds.northeast.latitude,
          east: bounds.northeast.longitude,
          zoom: zoom,
        );
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'DPM viewport prefetch');
    }
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    for (final sub in _filterListening) {
      for (final filter in sub.filters.values) {
        filter.values.removeListener(_onFilterChanged);
      }
    }
    _filterListening.clear();
    await _removeSubLayers(controller);
    _controller = null;
    _styleReady = false;
    close();
  }

  @override
  void onStyleReset() {
    // Style reload drops runtime layers; [render] re-adds when active.
    _styleReady = false;
  }

  void close() {
    for (final sub in subLayers) {
      sub.clearSelection();
    }
  }
}

/// A switchable DPM overlay (aed / restroom / shelter) — its tile source,
/// points layer, visibility, and tap-selection state.
abstract class DpmSubLayerBase {
  DpmSubLayerBase({
    required this.id,
    required this.sourceId,
    required this.pointsLayerId,
    required this.tileLayer,
    required this.color,
    required this.icon,
    this.filters = const {},
  });

  /// Tile-layer / route name (`aed`, `restroom`, `shelter`).
  final String id;

  final String sourceId;
  final String pointsLayerId;

  /// MVT source-layer name inside the tileset (matches [id]).
  final String tileLayer;

  /// Marker colour, as a MapLibre hex paint string.
  final String color;

  /// Leading icon for the overlay menu / legend, and the map marker's glyph.
  final IconData icon;

  /// Visible — on by default.
  final ValueNotifier<bool> visible = ValueNotifier(true);

  /// Filter dimensions keyed by tile property, when the sub-layer is
  /// filterable (restroom `type2` + `type`; shelter `category`; AED none).
  /// A dimension starts with nothing selected (no constraint); checking a
  /// chip narrows what renders to those values.
  final Map<String, DpmFilter> filters;

  final ValueNotifier<int?> selectionId = ValueNotifier<int?>(null);
  final ValueNotifier<int> selectionRevision = ValueNotifier<int>(0);
  final ValueNotifier<String?> previewName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> previewPlace = ValueNotifier<String?>(null);

  /// Typed [detail] slot — set on a successful fetch.
  void setDetail(Object? detail);

  /// Clears selection + preview + detail.
  void clearSelection() {
    selectionId.value = null;
    previewName.value = null;
    previewPlace.value = null;
    setDetail(null);
  }
}

/// One filterable dimension of a DPM sub-layer — the tile property it reads
/// and the values currently allowed to render.
final class DpmFilter {
  DpmFilter(this.property);

  /// Tile property this dimension filters on (`type2` / `type` / `category`).
  final String property;

  /// Values currently allowed to render; empty (the default) = no constraint.
  final ValueNotifier<Set<Object>> values = ValueNotifier(const <Object>{});
}

/// [DpmSubLayerBase] with a typed [detail] notifier for the sheet body.
final class DpmSubLayer<T> extends DpmSubLayerBase {
  DpmSubLayer({
    required super.id,
    required super.sourceId,
    required super.pointsLayerId,
    required super.tileLayer,
    required super.color,
    required super.icon,
    super.filters,
  });

  final ValueNotifier<T?> detail = ValueNotifier<T?>(null);

  @override
  void setDetail(Object? detail) => this.detail.value = detail as T?;
}

/// Mirrors the map marker's look — colour badge + white icon glyph — so the
/// legend reads as the same mark.
class _DpmSwatch extends StatelessWidget {
  const _DpmSwatch({
    required this.color,
    required this.icon,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: size * 0.65, color: Colors.white),
    );
  }
}
