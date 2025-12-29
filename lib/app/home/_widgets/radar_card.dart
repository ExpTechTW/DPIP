import 'dart:async';

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
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
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

  MapLibreMapController? _mapController;
  late Future<List<String>> radarListFuture;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _deviceHeading = 0.0;
  bool _mapReady = false;

  Future<void> _setupMapLayers() async {
    final controller = _mapController;
    if (controller == null) return;

    final sourceId = MapSourceIds.radar();
    final layerId = MapLayerIds.radar();

    try {
      final time = (await radarListFuture).last;
      final newTileUrl = Routes.radarTile(time);

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
    radarListFuture = ExpTech().getRadarList();
    _initCompass();
  }

  Future<void> _initCompass() async {
    final isSupported = await FlutterCompass.events != null;
    if (!isSupported) return;

    _compassSubscription = FlutterCompass.events?.listen((event) async {
      if (event.heading != null && mounted) {
        final newHeading = event.heading!;
        // 變化超過 1 度時才更新，避免頻繁刷新
        if ((newHeading - _deviceHeading).abs() > 1) {
          setState(() {
            _deviceHeading = newHeading;
          });
          _updateMapBearing();
        }
      }
    });
  }

  Future<void> _updateMapBearing() async {
    if (!_mapReady || _mapController == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.bearingTo(_deviceHeading),
        duration: const Duration(milliseconds: 150),
      );
    } catch (e) {
      // 忽略錯誤
    }
  }

  /// 地圖樣式載入完成後初始化方位
  Future<void> _initMapBearing() async {
    if (!_mapReady || _mapController == null) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || _mapController == null) return;
    try {
      await _mapController!.moveCamera(
        CameraUpdate.bearingTo(_deviceHeading),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 720,
      child: Stack(
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
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        onStyleLoadedCallback: () async {
                          _mapReady = true;
                          _setupMapLayers();
                          // 地圖載入完成後立即設置方位
                          _initMapBearing();
                        },
                        dragEnabled: false,
                        rotateGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        focusUserLocationWhenUpdated: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Layout.row.between(
                        children: [
                          Layout.row[8](
                            children: [
                              const Icon(Symbols.radar, size: 24),
                              Text(
                                '雷達回波'.i18n,
                                style: context.texts.titleMedium,
                              ),
                              FutureBuilder(
                                future: radarListFuture,
                                builder: (context, snapshot) {
                                  final data = snapshot.data;

                                  if (data == null)
                                    return const SizedBox.shrink();

                                  final style = context.texts.labelSmall
                                      ?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      );

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceContainer,
                                      border: Border.all(
                                        color: context.colors.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Layout.row[4](
                                      children: [
                                        Icon(
                                          Symbols.schedule_rounded,
                                          size: (style?.fontSize ?? 12) * 1.25,
                                          color:
                                              context.colors.onSurfaceVariant,
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
                onTap: () => context.push(
                  MapPage.route(
                    options: MapPageOptions(initialLayers: {MapLayer.radar}),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
