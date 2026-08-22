/// Taiwan street/building detail drawn over the ordinary base map.
///
/// The source is the clipped `gsi.mbtiles` OpenMapTiles dataset documented in
/// `map-layers-control.md`. It is deliberately a base-map option rather than a
/// [MapLayer]: radar, satellite, wind, and every other weather product remain
/// the active overlay while these streets sit underneath them.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const String gsiSourceId = 'gsi';
const String gsiOriginTileUrl =
    'https://static.lb.exptech.dev${ApiPaths.mapGsiV1}{z}/{x}/{y}.pbf';
const double gsiSourceMaxZoom = 14;
const double gsiDisplayMaxZoom = 18;
const List<double> gsiBounds = [114.28579, 10.32677, 122.3283, 26.43722];

const VectorSourceProperties gsiSourceProperties = VectorSourceProperties(
  tiles: [gsiOriginTileUrl],
  bounds: gsiBounds,
  minzoom: 0,
  maxzoom: gsiSourceMaxZoom,
  attribution: '© OpenStreetMap contributors © OpenMapTiles',
);

/// User-facing groups from the reference implementation. Some groups own two
/// MapLibre layers (fill + outline, or road casing + road body), but expose one
/// switch because either half alone is not meaningful cartography.
enum GsiLayerGroup {
  surface,
  parks,
  landUse,
  airportAreas,
  water,
  rivers,
  boundaries,
  buildings,
  roads,
  roadNames,
  waterNames,
  peaks,
  airportNames,
  placeNames,
  poi,
  houseNumbers,
}

/// State shared by the base-map menu and the native style owner.
class GsiOverlayController extends ChangeNotifier {
  bool _enabled = false;
  final Set<GsiLayerGroup> _groups = {...GsiLayerGroup.values};
  int _revision = 0;

  bool get enabled => _enabled;
  int get revision => _revision;
  int get enabledGroupCount => _groups.length;

  bool groupEnabled(GsiLayerGroup group) => _groups.contains(group);

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _revision++;
    notifyListeners();
  }

  void setGroupEnabled(GsiLayerGroup group, bool value) {
    final changed = value ? _groups.add(group) : _groups.remove(group);
    if (!changed) return;
    _revision++;
    notifyListeners();
  }

  void restoreAll() {
    if (_groups.length == GsiLayerGroup.values.length) return;
    _groups.addAll(GsiLayerGroup.values);
    _revision++;
    notifyListeners();
  }
}

/// Makes the one scaffold-owned controller available to every layer menu
/// without widening [MapLayer.buildTopTrailingChrome] for another base option.
class GsiOverlayScope extends InheritedNotifier<GsiOverlayController> {
  const GsiOverlayScope({
    super.key,
    required GsiOverlayController controller,
    required super.child,
  }) : super(notifier: controller);

  static GsiOverlayController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GsiOverlayScope>()?.notifier;
}

enum GsiLayerKind { fill, line, symbol }

@immutable
class GsiStyleLayer {
  const GsiStyleLayer({
    required this.id,
    required this.group,
    required this.kind,
    required this.sourceLayer,
    required this.properties,
    this.minZoom,
    this.filter,
  });

  final String id;
  final GsiLayerGroup group;
  final GsiLayerKind kind;
  final String sourceLayer;
  final LayerProperties properties;
  final double? minZoom;
  final dynamic filter;

  LayerProperties propertiesWithVisibility(bool visible) {
    final visibility = visible ? 'visible' : 'none';
    return switch (properties) {
      final FillLayerProperties value => value.copyWith(
        FillLayerProperties(visibility: visibility),
      ),
      final LineLayerProperties value => value.copyWith(
        LineLayerProperties(visibility: visibility),
      ),
      final SymbolLayerProperties value => value.copyWith(
        SymbolLayerProperties(visibility: visibility),
      ),
      _ => throw StateError('Unsupported GSI layer properties for $id'),
    };
  }
}

String _color(String value) => value.vision;

/// The exact source-layer mapping and visual hierarchy from the documented web
/// implementation, with a light palette added for the app's light theme.
List<GsiStyleLayer> gsiStyleLayers(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final halo = _color(dark ? '#212837' : '#F2F3F5');
  final text = _color(dark ? '#E8ECF2' : '#25282E');
  return [
    GsiStyleLayer(
      id: 'gsi-landcover',
      group: GsiLayerGroup.surface,
      kind: GsiLayerKind.fill,
      sourceLayer: 'landcover',
      properties: FillLayerProperties(
        fillColor: [
          'match',
          ['get', 'class'],
          'wood',
          _color(dark ? '#1F3324' : '#CFE3CA'),
          'grass',
          _color(dark ? '#233A26' : '#DBE8C9'),
          _color(dark ? '#212C22' : '#E5E8DD'),
        ],
        fillOpacity: 0.9,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-park',
      group: GsiLayerGroup.parks,
      kind: GsiLayerKind.fill,
      sourceLayer: 'park',
      properties: FillLayerProperties(
        fillColor: _color(dark ? '#274A2E' : '#CFE8D2'),
        fillOpacity: 0.55,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-park-outline',
      group: GsiLayerGroup.parks,
      kind: GsiLayerKind.line,
      sourceLayer: 'park',
      properties: LineLayerProperties(
        lineColor: _color(dark ? '#3F7A4A' : '#79A983'),
        lineWidth: 1,
        lineDasharray: const [2, 2],
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-landuse',
      group: GsiLayerGroup.landUse,
      kind: GsiLayerKind.fill,
      sourceLayer: 'landuse',
      properties: FillLayerProperties(
        fillColor: [
          'match',
          ['get', 'class'],
          'residential',
          _color(dark ? '#242830' : '#E3E1DD'),
          'commercial',
          _color(dark ? '#332226' : '#EADADC'),
          'industrial',
          _color(dark ? '#2A2436' : '#DDD8E8'),
          // Military land remains neutral: red means an alert in DPIP.
          'military',
          _color(dark ? '#2F2B33' : '#D8D4DC'),
          'school',
          _color(dark ? '#332F1F' : '#ECE6CC'),
          'university',
          _color(dark ? '#332F1F' : '#ECE6CC'),
          'cemetery',
          _color(dark ? '#1F2C22' : '#D6E4D7'),
          _color(dark ? '#242830' : '#E3E1DD'),
        ],
        fillOpacity: 0.85,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-aeroway-fill',
      group: GsiLayerGroup.airportAreas,
      kind: GsiLayerKind.fill,
      sourceLayer: 'aeroway',
      filter: const [
        'in',
        ['get', 'class'],
        [
          'literal',
          ['apron', 'aerodrome', 'heliport'],
        ],
      ],
      properties: FillLayerProperties(
        fillColor: _color(dark ? '#2E2C3D' : '#DEDCE8'),
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-aeroway-line',
      group: GsiLayerGroup.airportAreas,
      kind: GsiLayerKind.line,
      sourceLayer: 'aeroway',
      filter: const [
        'in',
        ['get', 'class'],
        [
          'literal',
          ['runway', 'taxiway'],
        ],
      ],
      properties: LineLayerProperties(
        lineColor: _color(dark ? '#5B5578' : '#8F89A7'),
        lineWidth: const [
          'match',
          ['get', 'class'],
          'runway',
          8,
          3,
        ],
      ),
    ),
    const GsiStyleLayer(
      id: 'gsi-water',
      group: GsiLayerGroup.water,
      kind: GsiLayerKind.fill,
      sourceLayer: 'water',
      // Transparent by design: the ExpTech base map supplies the sea colour,
      // avoiding a hard rectangle at the GSI dataset bounds.
      properties: FillLayerProperties(fillColor: 'rgba(0, 0, 0, 0)'),
    ),
    GsiStyleLayer(
      id: 'gsi-waterway',
      group: GsiLayerGroup.rivers,
      kind: GsiLayerKind.line,
      sourceLayer: 'waterway',
      properties: LineLayerProperties(
        lineColor: _color(dark ? '#2F6089' : '#5F96C4'),
        lineWidth: const [
          'match',
          ['get', 'class'],
          'river',
          2.5,
          'stream',
          1.2,
          1,
        ],
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-boundary',
      group: GsiLayerGroup.boundaries,
      kind: GsiLayerKind.line,
      sourceLayer: 'boundary',
      properties: LineLayerProperties(
        lineColor: [
          'step',
          ['get', 'admin_level'],
          _color(dark ? '#C77BC0' : '#8E4E8B'),
          3,
          _color(dark ? '#B579AE' : '#885C84'),
          5,
          _color(dark ? '#8A6A8B' : '#776174'),
          8,
          _color(dark ? '#5F5063' : '#6C626D'),
        ],
        lineWidth: const [
          'step',
          ['get', 'admin_level'],
          2.4,
          5,
          1.4,
          8,
          0.8,
        ],
        lineDasharray: const [3, 2],
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-building',
      group: GsiLayerGroup.buildings,
      kind: GsiLayerKind.fill,
      sourceLayer: 'building',
      minZoom: 13,
      properties: FillLayerProperties(
        fillColor: _color(dark ? '#3A3A3F' : '#D3D0CC'),
        fillOutlineColor: _color(dark ? '#55555C' : '#AAA59F'),
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-transportation-case',
      group: GsiLayerGroup.roads,
      kind: GsiLayerKind.line,
      sourceLayer: 'transportation',
      filter: const [
        '!=',
        ['get', 'class'],
        'ferry',
      ],
      properties: LineLayerProperties(
        lineColor: _color(dark ? '#0C0E14' : '#FFFFFF'),
        lineCap: 'round',
        lineJoin: 'round',
        lineWidth: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          8,
          [
            'match',
            ['get', 'class'],
            'motorway',
            1.2,
            'trunk',
            1,
            'primary',
            0.8,
            0.4,
          ],
          16,
          [
            'match',
            ['get', 'class'],
            'motorway',
            14,
            'trunk',
            11,
            'primary',
            9,
            [
              'match',
              ['get', 'class'],
              'service',
              3,
              'path',
              2,
              6,
            ],
          ],
        ],
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-transportation',
      group: GsiLayerGroup.roads,
      kind: GsiLayerKind.line,
      sourceLayer: 'transportation',
      filter: const [
        '!=',
        ['get', 'class'],
        'ferry',
      ],
      properties: LineLayerProperties(
        lineCap: 'round',
        lineJoin: 'round',
        lineColor: [
          'match',
          ['get', 'class'],
          'motorway',
          _color(dark ? '#E8A33D' : '#D4851F'),
          'trunk',
          _color(dark ? '#D99A4E' : '#C7822D'),
          'primary',
          _color(dark ? '#C99A5F' : '#B88942'),
          'secondary',
          _color(dark ? '#8F7A4F' : '#9A8157'),
          'rail',
          _color(dark ? '#7A7A82' : '#77777D'),
          'service',
          _color(dark ? '#3D3D44' : '#C7C4BE'),
          'path',
          _color(dark ? '#5F5540' : '#A89467'),
          _color(dark ? '#4A4A52' : '#B7B3AD'),
        ],
        lineWidth: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          8,
          [
            'match',
            ['get', 'class'],
            'motorway',
            1,
            'trunk',
            0.8,
            'primary',
            0.6,
            0.3,
          ],
          16,
          [
            'match',
            ['get', 'class'],
            'motorway',
            11,
            'trunk',
            8,
            'primary',
            6.5,
            [
              'match',
              ['get', 'class'],
              'service',
              1.5,
              'path',
              1,
              4,
            ],
          ],
        ],
        lineDasharray: const [
          'match',
          ['get', 'class'],
          'rail',
          [
            'literal',
            [2, 2],
          ],
          [
            'literal',
            [1, 0],
          ],
        ],
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-transportation-name',
      group: GsiLayerGroup.roadNames,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'transportation_name',
      minZoom: 13,
      properties: SymbolLayerProperties(
        symbolPlacement: 'line',
        textField: _nameExpression,
        textFont: const ['Noto Sans TC Regular'],
        textSize: 11,
        textColor: _color(dark ? '#D9B877' : '#725B25'),
        textHaloColor: halo,
        textHaloWidth: 1.2,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-water-name',
      group: GsiLayerGroup.waterNames,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'water_name',
      properties: SymbolLayerProperties(
        textField: _nameExpression,
        textFont: const ['Noto Sans TC Regular'],
        textSize: 12,
        textLetterSpacing: 0.05,
        textColor: _color(dark ? '#7CB3DE' : '#326D9A'),
        textHaloColor: halo,
        textHaloWidth: 1.2,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-mountain-peak',
      group: GsiLayerGroup.peaks,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'mountain_peak',
      properties: SymbolLayerProperties(
        textField: const [
          'format',
          _nameExpression,
          <String, Object>{},
          '\n',
          <String, Object>{},
          [
            'concat',
            [
              'to-string',
              ['get', 'ele'],
            ],
            'm',
          ],
          {'font-scale': 0.85},
        ],
        textFont: const ['Noto Sans TC Regular'],
        textSize: 12,
        textAnchor: 'top',
        textOffset: const [0, 0.4],
        textJustify: 'center',
        textColor: _color(dark ? '#D99A6C' : '#875332'),
        textHaloColor: halo,
        textHaloWidth: 1.4,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-aerodrome-label',
      group: GsiLayerGroup.airportNames,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'aerodrome_label',
      properties: SymbolLayerProperties(
        textField: _nameExpression,
        textFont: const ['Noto Sans TC Regular'],
        textSize: 13,
        textColor: _color(dark ? '#A89ADB' : '#66539C'),
        textHaloColor: halo,
        textHaloWidth: 1.4,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-place',
      group: GsiLayerGroup.placeNames,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'place',
      properties: SymbolLayerProperties(
        textField: _nameExpression,
        textFont: const ['Noto Sans TC Regular'],
        textSize: const [
          'match',
          ['get', 'class'],
          'country',
          18,
          'city',
          15,
          'town',
          13,
          'village',
          11,
          10,
        ],
        textColor: text,
        textHaloColor: halo,
        textHaloWidth: 1.4,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-poi',
      group: GsiLayerGroup.poi,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'poi',
      minZoom: 14,
      properties: SymbolLayerProperties(
        textField: _nameExpression,
        textFont: const ['Noto Sans TC Regular'],
        textSize: 10,
        textOffset: const [0, 0.6],
        textAnchor: 'top',
        textColor: _color(dark ? '#A9B4C2' : '#555D68'),
        textHaloColor: halo,
        textHaloWidth: 1,
      ),
    ),
    GsiStyleLayer(
      id: 'gsi-housenumber',
      group: GsiLayerGroup.houseNumbers,
      kind: GsiLayerKind.symbol,
      sourceLayer: 'housenumber',
      minZoom: 16,
      properties: SymbolLayerProperties(
        textField: const ['get', 'housenumber'],
        textFont: const ['Noto Sans TC Regular'],
        textSize: 9,
        textColor: _color(dark ? '#9A958A' : '#6F6A5F'),
      ),
    ),
  ];
}

const List<Object> _nameExpression = [
  'coalesce',
  ['get', 'name'],
  ['get', 'name:en'],
  ['get', 'name_int'],
];

Future<void> addGsiOverlay(
  MapLibreMapController controller, {
  required Brightness brightness,
  required GsiOverlayController selection,
  required String belowLayerId,
}) async {
  final layers = gsiStyleLayers(brightness);
  final added = <String>[];
  await controller.addSource(gsiSourceId, gsiSourceProperties);
  try {
    for (final layer in layers) {
      final properties = layer.propertiesWithVisibility(
        selection.groupEnabled(layer.group),
      );
      switch (layer.kind) {
        case GsiLayerKind.fill:
          await controller.addFillLayer(
            gsiSourceId,
            layer.id,
            properties as FillLayerProperties,
            belowLayerId: belowLayerId,
            sourceLayer: layer.sourceLayer,
            minzoom: layer.minZoom,
            filter: layer.filter,
            enableInteraction: false,
          );
          break;
        case GsiLayerKind.line:
          await controller.addLineLayer(
            gsiSourceId,
            layer.id,
            properties as LineLayerProperties,
            belowLayerId: belowLayerId,
            sourceLayer: layer.sourceLayer,
            minzoom: layer.minZoom,
            filter: layer.filter,
            enableInteraction: false,
          );
          break;
        case GsiLayerKind.symbol:
          await controller.addSymbolLayer(
            gsiSourceId,
            layer.id,
            properties as SymbolLayerProperties,
            belowLayerId: belowLayerId,
            sourceLayer: layer.sourceLayer,
            minzoom: layer.minZoom,
            filter: layer.filter,
            enableInteraction: false,
          );
          break;
      }
      added.add(layer.id);
    }
  } catch (_) {
    for (final id in added.reversed) {
      try {
        await controller.removeLayer(id);
      } catch (_) {}
    }
    try {
      await controller.removeSource(gsiSourceId);
    } catch (_) {}
    rethrow;
  }
}

Future<void> applyGsiLayerVisibility(
  MapLibreMapController controller,
  GsiOverlayController selection,
  Brightness brightness,
) => controller.setLayerPropertiesBatch([
  for (final layer in gsiStyleLayers(brightness))
    (
      layerId: layer.id,
      properties: layer.propertiesWithVisibility(
        selection.groupEnabled(layer.group),
      ),
    ),
], skipNulls: true);

Future<void> removeGsiOverlay(MapLibreMapController controller) async {
  for (final layer in gsiStyleLayers(Brightness.dark).reversed) {
    try {
      await controller.removeLayer(layer.id);
    } catch (_) {
      // A style reload or a partial add may already have removed this layer.
    }
  }
  try {
    await controller.removeSource(gsiSourceId);
  } catch (_) {
    // Same best-effort cleanup rule as the layers above.
  }
}

/// The street/building toggle plus a route to its detailed group switches.
class MapGsiOverlayControls extends StatelessWidget {
  const MapGsiOverlayControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GsiOverlayScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapMenuToggleRow(
            selected: controller.enabled,
            icon: Icons.apartment_outlined,
            title: l10n.mapGsiOverlay,
            subtitle: l10n.mapGsiOverlayHint,
            tooltip: l10n.mapGsiOverlayHint,
            closeOnActivate: false,
            onTap: () => controller.setEnabled(!controller.enabled),
          ),
          if (controller.enabled)
            _GsiDetailsRow(
              enabled: controller.enabledGroupCount,
              total: GsiLayerGroup.values.length,
              onPressed: () => _showDetails(navigatorContext, controller),
            ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, GsiOverlayController controller) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _GsiDetailsSheet(controller: controller),
      ),
    );
  }
}

class _GsiDetailsRow extends StatelessWidget {
  const _GsiDetailsRow({
    required this.enabled,
    required this.total,
    required this.onPressed,
  });

  final int enabled;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return MenuItemButton(
      onPressed: onPressed,
      style: MapChipButton.rowStyle(Colors.transparent),
      child: SizedBox(
        width: MapMenuToggleRow.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.layers_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mapGsiDetails),
                    Text(
                      l10n.mapGsiDetailsHint(enabled, total),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GsiDetailsSheet extends StatelessWidget {
  const _GsiDetailsSheet({required this.controller});

  final GsiOverlayController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mapGsiDetails,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.restoreAll,
                    child: Text(l10n.mapGsiRestoreAll),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  itemCount: GsiLayerGroup.values.length,
                  itemBuilder: (context, index) {
                    final group = GsiLayerGroup.values[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Material(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: AppRadius.medium,
                        child: SwitchListTile(
                          secondary: Icon(_groupIcon(group)),
                          title: Text(_groupLabel(l10n, group)),
                          value: controller.groupEnabled(group),
                          onChanged: (value) =>
                              controller.setGroupEnabled(group, value),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _groupLabel(AppLocalizations l10n, GsiLayerGroup group) =>
    switch (group) {
      GsiLayerGroup.surface => l10n.mapGsiSurface,
      GsiLayerGroup.parks => l10n.mapGsiParks,
      GsiLayerGroup.landUse => l10n.mapGsiLandUse,
      GsiLayerGroup.airportAreas => l10n.mapGsiAirportAreas,
      GsiLayerGroup.water => l10n.mapGsiWater,
      GsiLayerGroup.rivers => l10n.mapGsiRivers,
      GsiLayerGroup.boundaries => l10n.mapGsiBoundaries,
      GsiLayerGroup.buildings => l10n.mapGsiBuildings,
      GsiLayerGroup.roads => l10n.mapGsiRoads,
      GsiLayerGroup.roadNames => l10n.mapGsiRoadNames,
      GsiLayerGroup.waterNames => l10n.mapGsiWaterNames,
      GsiLayerGroup.peaks => l10n.mapGsiPeaks,
      GsiLayerGroup.airportNames => l10n.mapGsiAirportNames,
      GsiLayerGroup.placeNames => l10n.mapGsiPlaceNames,
      GsiLayerGroup.poi => l10n.mapGsiPoi,
      GsiLayerGroup.houseNumbers => l10n.mapGsiHouseNumbers,
    };

IconData _groupIcon(GsiLayerGroup group) => switch (group) {
  GsiLayerGroup.surface => Icons.landscape_outlined,
  GsiLayerGroup.parks => Icons.park_outlined,
  GsiLayerGroup.landUse => Icons.grid_view_outlined,
  GsiLayerGroup.airportAreas => Icons.flight_takeoff_outlined,
  GsiLayerGroup.water => Icons.water_outlined,
  GsiLayerGroup.rivers => Icons.water_drop_outlined,
  GsiLayerGroup.boundaries => Icons.border_style_outlined,
  GsiLayerGroup.buildings => Icons.apartment_outlined,
  GsiLayerGroup.roads => Icons.add_road_outlined,
  GsiLayerGroup.roadNames => Icons.signpost_outlined,
  GsiLayerGroup.waterNames => Icons.label_outline,
  GsiLayerGroup.peaks => Icons.terrain_outlined,
  GsiLayerGroup.airportNames => Icons.local_airport_outlined,
  GsiLayerGroup.placeNames => Icons.location_city_outlined,
  GsiLayerGroup.poi => Icons.place_outlined,
  GsiLayerGroup.houseNumbers => Icons.pin_outlined,
};
