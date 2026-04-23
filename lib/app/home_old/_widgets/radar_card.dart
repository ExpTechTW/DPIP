/// Radar map card that shows the latest precipitation radar imagery.
library;

import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/maplibre.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// An interactive card that embeds a read-only MapLibre radar overlay and
/// navigates to the full radar map when tapped.
class RadarMapCard extends StatefulWidget {
  /// Creates a [RadarMapCard].
  const RadarMapCard({super.key});

  @override
  State<RadarMapCard> createState() => _RadarMapCardState();
}

class _RadarMapCardState extends State<RadarMapCard> with WidgetsBindingObserver, RouteAware {
  MapLibreMapController? _mapController;

  /// Future that resolves to the list of available radar timestamps.
  late Future<List<String>> radarListFuture;

  Future<void> _setupMapLayers() async {
    final controller = _mapController;
    if (controller == null) return;

    final sourceId = MapSourceIds.radar();
    final layerId = MapLayerIds.radar();

    try {
      final time = (await radarListFuture).last;
      final newTileUrl = radarTile(time);

      if (await controller.exists(sourceId, source: true)) {
        await controller.removeSource(sourceId);
      }

      await controller.addSource(
        sourceId,
        RasterSourceProperties(tiles: [newTileUrl], tileSize: 256),
      );

      if (!mounted) return;

      if (!await controller.exists(layerId, layer: true)) {
        await controller.addLayer(
          sourceId,
          layerId,
          const RasterLayerProperties(),
          belowLayerId: BaseMapLayerIds.exptechCountyOutline,
        );
      }
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapCard._setupMapLayers', e, s);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    radarListFuture = ExpTech().getRadarList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = GlobalProviders.location.coordinates;
    final targetLocation = userLocation ?? DpipMap.kTaiwanCenter;
    final targetZoom = userLocation != null ? DpipMap.kUserLocationZoom : DpipMap.kTaiwanZoom;

    return ResponsiveContainer(
      maxWidth: 720,
      child: Stack(
        children: [
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                border: Border.all(color: context.colors.outlineVariant),
                borderRadius: .circular(16),
              ),
              child: ClipRRect(
                borderRadius: .circular(16),
                child: Layout.col.min(
                  children: [
                    SizedBox(
                      height: 200,
                      child: DpipMap(
                        initialCameraPosition: CameraPosition(
                          target: targetLocation,
                          zoom: targetZoom,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onStyleLoadedCallback: () => _setupMapLayers(),
                        dragEnabled: false,
                        rotateGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        focusUserLocationWhenUpdated: false,
                      ),
                    ),
                    Padding(
                      padding: const .symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Layout.row.between(
                        children: [
                          Layout.row[8](
                            children: [
                              const Icon(Symbols.radar_rounded, size: 24),
                              Text(
                                '雷達回波'.i18n,
                                style: context.texts.titleMedium,
                              ),
                              FutureBuilder(
                                future: radarListFuture,
                                builder: (context, snapshot) {
                                  final data = snapshot.data;

                                  if (data == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final style = context.texts.labelSmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  );

                                  return Container(
                                    padding: const .symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceContainer,
                                      border: Border.all(
                                        color: context.colors.outlineVariant,
                                      ),
                                      borderRadius: .circular(16),
                                    ),
                                    child: Layout.row[4](
                                      children: [
                                        Icon(
                                          Symbols.schedule_rounded,
                                          size: (style?.fontSize ?? 12) * 1.25,
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                        Text(
                                          data.last.toSimpleDateTimeString(),
                                          style: style,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Icon(
                            Symbols.chevron_right_rounded,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => MapRoute(layers: 'radar').push(context),
                borderRadius: .circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
