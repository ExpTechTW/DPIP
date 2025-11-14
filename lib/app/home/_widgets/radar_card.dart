import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/maplibre.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

typedef PositionUpdateCallback = void Function();

class RadarMapCard extends StatefulWidget {
  const RadarMapCard({super.key});

  @override
  State<RadarMapCard> createState() => _RadarMapCardState();
}

class _RadarMapCardState extends State<RadarMapCard> {
  late final _key = widget.key ?? UniqueKey();

  late MapLibreMapController mapController;
  late Future<List<String>> radarListFuture;

  Future<void> _setupMapLayers() async {
    final controller = mapController;

    final sourceId = MapSourceIds.radar();
    final layerId = MapLayerIds.radar();

    try {
      final time = (await radarListFuture).last;
      final newTileUrl = Routes.radarTile(time);

      if (await controller.exists(sourceId, source: true)) {
        await controller.removeSource(sourceId);
      }

      await controller.addSource(sourceId, RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));

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
    radarListFuture = ExpTech().getRadarList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              border: Border.all(color: context.colors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Layout.col.min(
                children: [
                  SizedBox(
                    height: 200,
                    child: DpipMap(
                      key: _key,
                      onMapCreated: (controller) => mapController = controller,
                      onStyleLoadedCallback: () => _setupMapLayers(),
                      dragEnabled: false,
                      rotateGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      focusUserLocationWhenUpdated: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Layout.row.between(
                      children: [
                        Layout.row[8](
                          children: [
                            const Icon(Symbols.radar, size: 24),
                            Text('雷達回波'.i18n, style: context.textTheme.titleMedium),
                            FutureBuilder(
                              future: radarListFuture,
                              builder: (context, snapshot) {
                                final data = snapshot.data;

                                if (data == null) return const SizedBox.shrink();

                                final style = context.textTheme.labelSmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                );

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceContainer,
                                    border: Border.all(color: context.colors.outlineVariant),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Layout.row[4](
                                    children: [
                                      Icon(
                                        Symbols.schedule_rounded,
                                        size: (style?.fontSize ?? 12) * 1.25,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                      Text(data.last.toSimpleDateTimeString(), style: style),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Icon(Symbols.chevron_right_rounded, size: 24),
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
              onTap: () => context.push(MapPage.route(options: MapPageOptions(initialLayers: {MapLayer.radar}))),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
