import 'package:dpip/app/map/radar/page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:dpip/widgets/map/map.dart';

typedef PositionUpdateCallback = void Function();

class RadarMapCard extends StatefulWidget {
  const RadarMapCard({super.key});

  @override
  State<RadarMapCard> createState() => _RadarMapCardState();
}

class _RadarMapCardState extends State<RadarMapCard> {
  late MapLibreMapController mapController;
  List<String> radarList = [];

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  String _getTileUrl(String timestamp) {
    return 'https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png';
  }

  Future<void> _initializeMap(LatLng userLocation) async {
    await loadGPSImage(mapController);

    radarList = await ExpTech().getRadarList();
    if (!mounted) return;

    await _setupRadarLayer();
    if (userLocation.isValid) {
      await _setupUserLocationLayer(userLocation);
    }
  }

  Future<void> _setupRadarLayer() async {
    final newTileUrl = _getTileUrl(radarList.last);
    await mapController.addSource('radar-source', RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));

    mapController.addLayer('radar-source', 'radar', const RasterLayerProperties(), belowLayerId: 'county-outline');
  }

  Future<void> _setupUserLocationLayer(LatLng userLocation) async {
    await mapController.addSource(
      'gps-geojson',
      GeojsonSourceProperties(data: GeoJsonBuilder().addFeature(userLocation.toFeatureBuilder()).build()),
    );

    await mapController.addLayer(
      'gps-geojson',
      'gps',
      const SymbolLayerProperties(
        symbolZOrder: 'source',
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          5,
          0.5,
          10,
          1.5,
        ],
        iconImage: 'gps',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    child: Selector<SettingsLocationModel, ({double? latitude, double? longitude})>(
                      selector: (context, location) => (latitude: location.latitude, longitude: location.longitude),
                      builder: (context, data, _) {
                        final userLocation = LatLng(data.latitude ?? 0, data.longitude ?? 0);

                        return DpipMap(
                          key: UniqueKey(),
                          onMapCreated: (controller) => mapController = controller,
                          onStyleLoadedCallback: () => _initializeMap(userLocation),
                          initialCameraPosition:
                              userLocation.isValid
                                  ? CameraPosition(target: userLocation, zoom: 7)
                                  : const CameraPosition(target: LatLng(23.10, 120.85), zoom: 6.2),
                          dragEnabled: false,
                          rotateGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Icon(Symbols.radar, size: 24),
                            Text(context.i18n.radar_monitor, style: context.textTheme.titleMedium),
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
            color: Colors.transparent,
            child: InkWell(onTap: () => context.push(MapRadarPage.route), borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
