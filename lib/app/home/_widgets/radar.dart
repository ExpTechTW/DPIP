/// A home-page card that embeds a read-only radar map preview.
library;

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/maplibre.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A card that shows the latest precipitation radar imagery on a mini map.
///
/// Tapping the map area navigates to the full radar layer on the map page.
/// Manages the [MapLibreMapController] lifecycle via [RouteAware] and
/// [WidgetsBindingObserver].
class Radar extends StatefulWidget {
  /// Creates a [Radar] card.
  const Radar({super.key});

  @override
  State<Radar> createState() => _RadarState();
}

class _RadarState extends State<Radar> with WidgetsBindingObserver, RouteAware {
  MapLibreMapController? _mapController;
  bool _homeListenerAdded = false;

  /// Resolves to the list of available radar timestamps once fetched.
  late Future<List<String>> _radarListFuture;

  void _onHomeModelChanged() {
    final code = context.home.temporaryCode ?? GlobalProviders.location.code;
    final LatLng target;
    final double zoom;

    if (code != null && Global.location[code] != null) {
      final loc = Global.location[code]!;
      target = LatLng(loc.lat, loc.lng);
      zoom = DpipMap.kUserLocationZoom;
    } else if (GlobalProviders.location.coordinates != null) {
      target = GlobalProviders.location.coordinates!;
      zoom = DpipMap.kUserLocationZoom;
    } else {
      target = DpipMap.kTaiwanCenter;
      zoom = DpipMap.kTaiwanZoom;
    }

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _setupMapLayers() async {
    final controller = _mapController;
    if (controller == null) return;

    final sourceId = MapSourceIds.radar();
    final layerId = MapLayerIds.radar();

    try {
      final time = (await _radarListFuture).last;
      final tileUrl = radarTile(time);

      if (await controller.exists(sourceId, source: true)) {
        await controller.removeSource(sourceId);
      }

      await controller.addSource(
        sourceId,
        RasterSourceProperties(tiles: [tileUrl], tileSize: 256),
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
      TalkerManager.instance.error('Radar._setupMapLayers', e, s);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _radarListFuture = ExpTech().getRadarList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);

    if (!_homeListenerAdded) {
      context.home.addListener(_onHomeModelChanged);
      _homeListenerAdded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = GlobalProviders.location.coordinates;
    final targetLocation = userLocation ?? DpipMap.kTaiwanCenter;
    final targetZoom = userLocation != null ? DpipMap.kUserLocationZoom : DpipMap.kTaiwanZoom;

    return Padding(
      padding: .symmetric(horizontal: 12, vertical: 4),
      child: Card(
        clipBehavior: .antiAlias,
        child: InkWell(
          onTap: () => MapRoute(layers: 'radar').push(context),
          child: Padding(
            padding: .all(12),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 12,
              children: [
                Row(
                  spacing: 4,
                  children: [
                    Icon(Symbols.radar_rounded, fill: 1, color: Colors.lightBlue),
                    BodyText.large('雷達回波'.i18n, weight: .bold),
                    FutureBuilder(
                      future: _radarListFuture,
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        if (data == null) return const SizedBox.shrink();

                        return Container(
                          padding: .fromLTRB(6, 4, 8, 4),
                          decoration: BoxDecoration(
                            borderRadius: .circular(64),
                            color: context.colors.surfaceContainerHighest,
                          ),
                          child: Row(
                            spacing: 4,
                            mainAxisSize: .min,
                            children: [
                              Icon(
                                Symbols.schedule_rounded,
                                size: 14,
                                color: context.colors.onSurfaceVariant,
                              ),
                              LabelText.medium(
                                data.last.toSimpleDateTimeString(),
                                color: context.colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Icon(
                      Symbols.chevron_right_rounded,
                      size: 16,
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: .circular(12),
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 200,
                      child: DpipMap(
                        initialCameraPosition: CameraPosition(
                          target: targetLocation,
                          zoom: targetZoom,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onStyleLoadedCallback: _setupMapLayers,
                        dragEnabled: false,
                        rotateGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        focusUserLocationWhenUpdated: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    context.home.removeListener(_onHomeModelChanged);
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
