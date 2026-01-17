import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/compass.dart';
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
import 'package:flutter_compass/flutter_compass.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

class RadarMapCard extends StatefulWidget {
  const RadarMapCard({super.key});

  @override
  State<RadarMapCard> createState() => _RadarMapCardState();
}

class _RadarMapCardState extends State<RadarMapCard>
    with WidgetsBindingObserver, RouteAware {
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
    WidgetsBinding.instance.addObserver(this);
    radarListFuture = ExpTech().getRadarList();
    _initCompass();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initCompass();
      _updateMapBearing();
    } else if (state == AppLifecycleState.paused) {
      _compassSubscription?.cancel();
      _compassSubscription = null;
    }
  }

  @override
  void didPopNext() {
    _initCompass();
    _updateMapBearing();
  }

  @override
  void didPush() {
    if (_compassSubscription == null) {
      _initCompass();
    }
  }

  @override
  void didPushNext() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  void _initCompass() {
    if (_compassSubscription != null) return;

    final compass = CompassService.instance;
    if (!compass.hasCompass) return;

    _deviceHeading = compass.lastHeading;

    _compassSubscription = compass.events?.listen((event) {
      if (event.heading != null && mounted) {
        final newHeading = event.heading!;
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
    } catch (_) {}
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = GlobalProviders.location.coordinates;
    final targetLocation = userLocation ?? DpipMap.kTaiwanCenter;
    final targetZoom = userLocation != null
        ? DpipMap.kUserLocationZoom
        : DpipMap.kTaiwanZoom;
    final bearing = CompassService.instance.lastHeading;

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
                        initialCameraPosition: CameraPosition(
                          target: targetLocation,
                          zoom: targetZoom,
                          bearing: bearing,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        onStyleLoadedCallback: () {
                          _mapReady = true;
                          _setupMapLayers();
                          _deviceHeading = CompassService.instance.lastHeading;
                        },
                        dragEnabled: false,
                        rotateGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        focusUserLocationWhenUpdated: false,
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

                                  if (data == null) {
                                    return const SizedBox.shrink();
                                  }

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
                onTap: () => MapRoute(layers: 'radar').push(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
