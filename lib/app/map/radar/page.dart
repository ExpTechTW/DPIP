import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:dpip/utils/radar_color.dart';
import 'package:dpip/widgets/list/time_selector.dart';
import 'package:dpip/widgets/map/legend.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:provider/provider.dart';

typedef PositionUpdateCallback = void Function();

class MapRadarPage extends StatefulWidget {
  static const String route = '/map/radar';

  const MapRadarPage({super.key});

  @override
  State<MapRadarPage> createState() => _MapRadarPageState();
}

class _MapRadarPageState extends State<MapRadarPage> {
  late MapLibreMapController mapController;
  List<String> radarList = [];

  bool _showLegend = false;

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
      await _centerMapOnUser(userLocation);
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

  Future<void> _centerMapOnUser(LatLng userLocation) async {
    final cameraUpdate = CameraUpdate.newLatLngZoom(userLocation, 7);
    await mapController.moveCamera(cameraUpdate);
  }

  void _toggleLegend() {
    setState(() => _showLegend = !_showLegend);
  }

  Widget _buildLegend() {
    return MapLegend(
      children: [
        _buildColorBar(),
        const SizedBox(height: 8),
        _buildColorBarLabels(),
        const SizedBox(height: 12),
        Text(context.i18n.unit_dbz, style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildColorBar() {
    return SizedBox(height: 20, width: 300, child: CustomPaint(painter: ColorBarPainter(dBZColors)));
  }

  Widget _buildColorBarLabels() {
    final labels = List.generate(14, (index) => (index * 5).toString());
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.map((label) => Text(label, style: const TextStyle(fontSize: 9))).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Selector<SettingsLocationModel, ({double? latitude, double? longitude})>(
            selector: (context, model) => (latitude: model.latitude, longitude: model.longitude),
            builder: (context, data, _) {
              final userLocation = LatLng(data.latitude ?? 0, data.longitude ?? 0);

              return DpipMap(
                onMapCreated: (controller) => mapController = controller,
                onStyleLoadedCallback: () => _initializeMap(userLocation),
                rotateGesturesEnabled: true,
              );
            },
          ),
          Positioned(
            left: 4,
            bottom: 4 + context.padding.bottom,
            child: Material(
              color: context.colors.secondary,
              elevation: 4.0,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleLegend,
                child: Tooltip(
                  message: context.i18n.map_legend,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    child: Icon(
                      _showLegend ? Icons.close : Icons.info_outline,
                      size: 20,
                      color: context.colors.onSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (radarList.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 2 + context.padding.bottom,
              child: TimeSelector(
                timeList: radarList,
                onTimeExpanded: () => setState(() => _showLegend = false),
                onTimeSelected: (time) {
                  final newTileUrl = _getTileUrl(time);

                  mapController.removeLayer('radarLayer');
                  mapController.removeSource('radarSource');

                  mapController.addSource('radarSource', RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));

                  mapController.addLayer(
                    'radarSource',
                    'radarLayer',
                    const RasterLayerProperties(),
                    belowLayerId: 'county-outline',
                  );
                },
              ),
            ),
          if (_showLegend) Positioned(left: 6, bottom: 50, child: _buildLegend()),
        ],
      ),
    );
  }
}

class ColorBarPainter extends CustomPainter {
  final List<String> colors;

  ColorBarPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final width = size.width / colors.length;

    for (int i = 0; i < colors.length; i++) {
      paint.color = Color(int.parse('0xFF${colors[i]}'));
      canvas.drawRect(Rect.fromLTWH(i * width, 0, width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
