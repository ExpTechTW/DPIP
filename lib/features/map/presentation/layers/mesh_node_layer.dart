/// The Meshtastic node map layer — every mesh node that has reported a
/// position, coloured by whether it has been heard recently.
///
/// A sheet layer, not a timeline one: nodes have no frames, they have a
/// current state. It draws straight from [MeshNodeStore], so it works with no
/// radio attached — the last known mesh is exactly what you want to see when
/// you are trying to reach one.
library;

import 'dart:async';
import 'dart:ui';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/features/map/presentation/widgets/mesh_node_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_terrain_toggle.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MeshNodeMapLayer with MapLayerDefaults implements MapLayer {
  MeshNodeMapLayer(this._store);

  final MeshNodeStore _store;

  static const String _sourceId = 'mesh-node-src';
  static const String _circleId = 'mesh-node-circle';
  static const String _labelId = 'mesh-node-label';

  /// Zoom at which a node's readings join its name on the map. Below this the
  /// dots are a distribution; above it the user is looking at individuals.
  static const double _detailZoom = 12;

  /// Tap tolerance, in the same logical pixels a touch target is measured in.
  ///
  /// A fixed degree radius is only ever right at one zoom: 0.05° is five
  /// kilometres, which is most of the screen in a street view and a couple of
  /// pixels when the whole island is showing — so zoomed out, the dots became
  /// almost unhittable. Screen distance is what the finger actually works in,
  /// and 44 px is the standard minimum touch target.
  static const double _tapRadiusPx = 44;

  /// Heard within [MeshNodeStore.onlineWindow] — a node that is part of the
  /// mesh right now.
  static const String _onlineColor = '#4CAF50';

  /// Known, but silent for a while. Kept on the map rather than hidden: a
  /// repeater that was there yesterday is still where you would go looking.
  static const String _offlineColor = '#9E9E9E';

  /// Only ever heard through an MQTT bridge. A different hue, not a shade of
  /// the same one: it is a different *kind* of thing — an internet report of a
  /// node, not a radio contact — so it must not read as "a slightly less
  /// online node".
  static const String _mqttColor = '#7E57C2';
  static const String _strokeColor = '#FFFFFF';

  /// Ring around the tapped node — the map has to answer "which one did I
  /// tap?" without the user having to compare the sheet to the dots.
  static const String _selectedColor = '#1E88E5';

  MapLibreMapController? _controller;
  bool _added = false;
  bool _listening = false;

  /// The tapped node, or null. A [ValueNotifier] because the sheet is a widget
  /// and this class is not — the scaffold rebuilds it from this.
  final ValueNotifier<int?> _selected = ValueNotifier<int?>(null);

  /// Bumped on every selecting tap, so tapping the same node again re-pops a
  /// sheet the user had collapsed — a same-value notifier would not notify.
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);

  @override
  String get id => 'meshtastic';

  @override
  IconData get icon => Icons.hub_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMeshtastic;

  @override
  String? subtitle(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMeshtasticSubtitle;

  @override
  bool get usesTimeline => false;

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
    await controller.addCircleLayer(_sourceId, _circleId, _circleProps());
    // Names only from mid zoom: a dense urban mesh would otherwise be a wall
    // of overlapping labels.
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      _labelProps(),
      minzoom: 9,
    );
    _added = true;
    if (!_listening) {
      _store.addListener(_onNodes);
      _listening = true;
    }
  }

  void _onNodes() => unawaited(_push());

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (_store.positioned.isEmpty) return;
    final best = await _nodeNear(latLng, controller);
    if (best == null) return;
    _selected.value = best;
    _selectionRevision.value++;
    // The selected node draws with a ring, so the map has to be re-pushed.
    await _push();
  }

  /// The node under (or near) a tap.
  ///
  /// Asks **MapLibre** rather than doing the geometry here: it hit-tests the
  /// marks it actually rendered, in its own coordinate space, which is the one
  /// place where "did the finger land on the dot" is answered the same way on
  /// both platforms. Hand-rolled alternatives kept getting the units wrong —
  /// degrees don't scale with zoom, and the two platforms' projections don't
  /// even report the same kind of pixel (iOS logical points, Android device
  /// pixels), which is why the pad below is scaled per platform.
  Future<int?> _nodeNear(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {
    try {
      final tap = await controller.toScreenLocation(latLng);
      final pad = _tapRadiusPx * _screenScale;
      final rect = Rect.fromCenter(
        center: Offset(tap.x.toDouble(), tap.y.toDouble()),
        width: pad * 2,
        height: pad * 2,
      );
      final features = await controller.queryRenderedFeaturesInRect(rect, [
        _circleId,
        _labelId,
      ], null);
      for (final feature in features) {
        if (feature is! Map) continue;
        final properties = feature['properties'];
        if (properties is! Map) continue;
        final value = properties['num'];
        if (value is int) return value;
        if (value is double) return value.toInt();
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh node hit test');
    }
    return null;
  }

  /// Android reports screen coordinates in device pixels, iOS in logical
  /// points — so the same tolerance means different things unless it is
  /// scaled.
  double get _screenScale => defaultTargetPlatform == TargetPlatform.android
      ? PlatformDispatcher.instance.views.first.devicePixelRatio
      : 1.0;

  @override
  Widget buildSheet(BuildContext context) => MeshNodeSheet(
    store: _store,
    selected: _selected,
    selectionRevision: _selectionRevision,
    onClose: () {
      _selected.value = null;
      unawaited(_push());
    },
  );

  /// The collapsed peek the scaffold frames around — the sheet is always
  /// present, just resting at its handle when nothing is selected.
  @override
  double get bottomChromeFraction => MeshNodeSheet.peekExtent;

  Future<void> _push() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    try {
      await controller.setGeoJsonSource(_sourceId, _geoJson());
    } catch (_) {
      // The style can reload underneath us; the next render re-adds.
    }
  }

  Map<String, dynamic> _geoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final node in _store.positioned)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [node.longitude, node.latitude],
          },
          'properties': {
            'num': node.num,
            'name': _shortLabel(node),
            // Precomposed rather than concatenated in the style: an empty
            // detail would otherwise leave a trailing blank line under the
            // name.
            'label': _twoLineLabel(node),
            'online': _store.isOnline(node) ? 1 : 0,
            'mqtt': node.viaMqtt ? 1 : 0,
            'selected': node.num == _selected.value ? 1 : 0,
          },
        },
    ],
  };

  /// Node names run long (`故宮南院 東側山線 (Heltec V3)`); the map shows a
  /// readable stub and the mesh page has the full list.
  String _shortLabel(MeshNode node) {
    final name = node.displayName.trim();
    if (name.isEmpty) return '0x${node.num.toRadixString(16)}';
    return name.characters.length <= 12 ? name : '${name.characters.take(12)}…';
  }

  /// Name over its readings, for the close-in zooms.
  ///
  /// Deliberately **no "heard N minutes ago"** here. This string is baked into
  /// the map source and only rewritten when the store changes — so for a node
  /// that has gone quiet, which is exactly the node whose age matters, the
  /// label would freeze at whatever it said when the node last reported and
  /// then keep claiming it. A frozen age is worse than none: the dot's colour
  /// already separates heard-recently from silent, and the sheet carries a
  /// live "last heard" because it rebuilds.
  // l10n-ignore: numeric readouts
  String _twoLineLabel(MeshNode node) {
    final name = _shortLabel(node);
    final parts = <String>[
      if (node.batteryLevel != null)
        node.batteryLevel! > 100 ? 'DC' : '${node.batteryLevel}%',
      if (node.snr != 0) 'SNR ${node.snr.toStringAsFixed(1)}',
    ];
    return parts.isEmpty ? name : '$name\n${parts.join(' · ')}';
  }

  CircleLayerProperties _circleProps() => CircleLayerProperties(
    // Grown from 3–7: a node is a thing to tap, and the dot has to look like
    // the target the hit test actually allows.
    circleRadius: [
      Expressions.interpolate,
      ['linear'],
      [Expressions.zoom],
      6,
      4.5,
      12,
      9.0,
    ],
    circleColor: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'mqtt'],
        1,
      ],
      _mqttColor,
      [
        Expressions.equal,
        [Expressions.get, 'online'],
        1,
      ],
      _onlineColor,
      _offlineColor,
    ],
    circleStrokeWidth: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'selected'],
        1,
      ],
      3.0,
      1.0,
    ],
    circleStrokeColor: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'selected'],
        1,
      ],
      _selectedColor,
      _strokeColor,
    ],
    circleOpacity: [
      Expressions.caseExpression,
      [
        Expressions.equal,
        [Expressions.get, 'online'],
        1,
      ],
      1.0,
      0.55,
    ],
  );

  /// **One** symbol layer, not two.
  ///
  /// `stationLabelProps` is built for a single two-line label — it owns the
  /// offset under the dot and the CJK-aware line height. Two stacked layers
  /// would each claim that same offset (drawing the second line on top of the
  /// first) and then collide-avoid *each other*, so a node would keep losing
  /// one of its own lines. A `step` on zoom switches between the one-line and
  /// two-line strings instead: the readings appear only once the map is close
  /// enough to attribute them to a specific node.
  SymbolLayerProperties _labelProps() => stationLabelProps(
    textField: [
      'step',
      [Expressions.zoom],
      [Expressions.get, 'name'],
      _detailZoom,
      [Expressions.get, 'label'],
    ],
    opacity: 1,
  );

  @override
  Future<void> clear(MapLibreMapController controller) async {
    if (_listening) {
      _store.removeListener(_onNodes);
      _listening = false;
    }
    _selected.value = null;
    await _removeFromMap(controller);
    _controller = null;
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    if (!_added) return;
    _added = false;
    for (final layerId in [_labelId, _circleId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Not present — the style may have been rebuilt under us.
      }
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Same.
    }
  }

  /// The key for the two dot colours.
  ///
  /// Without it the map shows green and grey dots and never says which is
  /// which — the one thing a reader cannot work out by looking.
  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // `MapLegendCard` is the surface every other layer's legend sits on —
    // without it the swatches float straight on the map and the labels fight
    // whatever tiles happen to be underneath.
    return MapLegendCard(
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => SymbolLegend(
          items: [
            SymbolLegendItem(
              swatch: const LegendDot(color: Color(0xFF4CAF50)),
              label: l10n.meshtasticOnline,
            ),
            SymbolLegendItem(
              swatch: const LegendDot(color: Color(0xFF9E9E9E)),
              label: l10n.meshtasticSilent,
            ),
            // Only keyed when such nodes can actually be on the map: a legend
            // row for something the filter is hiding is noise.
            if (!_store.excludeMqtt)
              SymbolLegendItem(
                swatch: const LegendDot(color: Color(0xFF7E57C2)),
                label: l10n.meshtasticViaMqtt,
              ),
          ],
        ),
      ),
    );
  }

  /// Layer-specific chrome beside the layer switcher: the MQTT filter, plus
  /// the shared base-map toggles so the user has one menu rather than three.
  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => _MeshNodeMenu(
    store: _store,
    onExcludeMqttChanged: (exclude) async {
      await _store.setExcludeMqtt(exclude: exclude);
      await _push();
    },
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  void onStyleReset() {
    _added = false;
    _controller = null;
  }
}

/// The mesh layer's overlay menu.
class _MeshNodeMenu extends StatelessWidget {
  const _MeshNodeMenu({
    required this.store,
    required this.onExcludeMqttChanged,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
    required this.showTerrain,
    required this.onShowTerrainChanged,
  });

  final MeshNodeStore store;
  final ValueChanged<bool> onExcludeMqttChanged;
  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;
  final ValueListenable<bool> showTerrain;
  final ValueChanged<bool> onShowTerrainChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([store, showTownLabels, showTerrain]),
      builder: (context, _) {
        final excludeMqtt = store.excludeMqtt;
        final hidden = store.hiddenMqttCount;
        // The chip marks a *deviation from the defaults*, and hiding MQTT is
        // the default here — so only the opposite lights it up.
        final active =
            !excludeMqtt || !showTownLabels.value || !showTerrain.value;
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: MapChipButton.menuStyle(context),
          builder: (context, controller, _) => MapChipButton(
            icon: Icons.tune,
            tooltip: l10n.meshtasticLayerOptions,
            active: active,
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          menuChildren: [
            MapMenuScrollView(
              children: [
                SectionHeader(l10n.meshtasticNodes),
                MapMenuToggleRow(
                  selected: excludeMqtt,
                  icon: Icons.cloud_off_outlined,
                  title: l10n.meshtasticExcludeMqtt,
                  subtitle: excludeMqtt && hidden > 0
                      ? l10n.meshtasticExcludeMqttHidden(hidden)
                      : l10n.meshtasticExcludeMqttSubtitle,
                  tooltip: l10n.meshtasticExcludeMqttSubtitle,
                  onTap: () => onExcludeMqttChanged(!excludeMqtt),
                ),
                const MapMenuDivider(),
                // The shared base-map rows, not copies of them: this menu
                // replaces the standalone base-map chip, so the toggles have
                // to be the same ones the user finds on every other layer.
                MapTownLabelsRow(
                  showTownLabels: showTownLabels,
                  onShowTownLabelsChanged: onShowTownLabelsChanged,
                ),
                MapTerrainRow(
                  showTerrain: showTerrain,
                  onShowTerrainChanged: onShowTerrainChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
