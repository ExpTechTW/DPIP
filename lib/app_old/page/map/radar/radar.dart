import "dart:io";

import "package:dpip/api/exptech.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/map_utils.dart";
import "package:dpip/utils/need_location.dart";
import "package:dpip/utils/radar_color.dart";
import "package:dpip/widgets/list/time_selector.dart";
import "package:dpip/widgets/map/legend.dart";
import "package:dpip/widgets/map/map.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";

typedef PositionUpdateCallback = void Function();

class RadarMap extends StatefulWidget {
  final Function()? onPositionUpdate;

  const RadarMap({super.key, this.onPositionUpdate});

  @override
  State<RadarMap> createState() => _RadarMapState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition() {
    _activeCallback?.call();
  }
}

class _RadarMapState extends State<RadarMap> {
  late MapLibreMapController _mapController;

  List<String> radar_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;

  String getTileUrl(String timestamp) {
    return "https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png";
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  @override
  void initState() {
    super.initState();
    RadarMap.setActiveCallback(sendpositionUpdate);
  }

  void sendpositionUpdate() {
    if (mounted) {
      start();
      widget.onPositionUpdate?.call();
    }
  }

  @override
  void dispose() {
    RadarMap.clearActiveCallback();
    _mapController.dispose();
    super.dispose();
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _addUserLocationMarker() async {
    if (isUserLocationValid) {
      await _mapController.removeLayer("markers");
      await _mapController.addLayer(
        "markers-geojson",
        "markers",
        const SymbolLayerProperties(
          symbolZOrder: "source",
          iconSize: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.5,
          ],
          iconImage: "gps",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    }
  }

  void _loadMap() async {
    final isDark = context.theme.brightness == Brightness.dark;

    await _loadMapImages(isDark);

    radar_list = await ExpTech().getRadarList();

    String newTileUrl = getTileUrl(radar_list.last);

    _mapController.addSource("radarSource", RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));

    _mapController.removeLayer("county-outline");
    _mapController.removeLayer("county");

    _mapController.addLayer(
      "map",
      "county",
      FillLayerProperties(fillColor: context.colors.surfaceContainerHigh.toHexStringRGB(), fillOpacity: 1),
      sourceLayer: "city",
      belowLayerId: "radarLayer",
    );

    _mapController.addLayer(
      "map",
      "county-outline",
      LineLayerProperties(lineColor: context.colors.outline.toHexStringRGB()),
      sourceLayer: "city",
    );

    _mapController.addLayer("radarSource", "radarLayer", const RasterLayerProperties(), belowLayerId: "county-outline");

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }

    await _mapController.addSource(
      "markers-geojson",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );

    start();
  }

  void start() async {
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (isUserLocationValid) {
      await _mapController.setGeoJsonSource("markers-geojson", {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "properties": {},
            "geometry": {
              "coordinates": [userLon, userLat],
              "type": "Point",
            },
          },
        ],
      });
      final cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(userLat, userLon), 8);
      await _mapController.animateCamera(cameraUpdate, duration: const Duration(milliseconds: 1000));
    }

    if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
      await showLocationDialog(context);
    }

    _addUserLocationMarker();

    setState(() {});
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
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
    return Stack(
      children: [
        DpipMap(onMapCreated: _initMap, onStyleLoadedCallback: _loadMap, rotateGesturesEnabled: true),
        Positioned(
          left: 4,
          bottom: 4,
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
        if (radar_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: radar_list,
              onTimeExpanded: () {
                _showLegend = false;
                setState(() {});
              },
              onTimeSelected: (time) {
                String newTileUrl = getTileUrl(time);

                _mapController.removeLayer("radarLayer");
                _mapController.removeSource("radarSource");

                _mapController.addSource("radarSource", RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));

                _mapController.addLayer(
                  "radarSource",
                  "radarLayer",
                  const RasterLayerProperties(),
                  belowLayerId: "county-outline",
                );

                _addUserLocationMarker();
              },
            ),
          ),
        if (_showLegend)
          Positioned(
            left: 6,
            bottom: 50, // Adjusted to be above the legend button
            child: _buildLegend(),
          ),
      ],
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
      paint.color = Color(int.parse("0xFF${colors[i]}"));
      canvas.drawRect(Rect.fromLTWH(i * width, 0, width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
