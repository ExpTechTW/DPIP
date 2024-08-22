import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/model/weather/lightning.dart';

class LightningData {
  final double latitude;
  final double longitude;
  final int type;
  final int time;

  LightningData({
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.time,
  });
}

class LightningMap extends StatefulWidget {
  const LightningMap({Key? key}) : super(key: key);

  @override
  State<LightningMap> createState() => _LightningMapState();
}

class _LightningMapState extends State<LightningMap> {
  late MapLibreMapController _mapController;
  List<String> lightningTimeList = [];
  List<LightningData> lightningDataList = [];
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    _loadLightningTimeList();
  }

  Future<void> _loadLightningTimeList() async {
    lightningTimeList = await ExpTech().getLightningList();
    setState(() {});
  }

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
    _loadMap();
  }

  Future<void> _loadMap() async {
    await _loadMapImages();
    await _mapController.addSource(
      "lightning-data",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );
    if (lightningTimeList.isNotEmpty) {
      await _loadLightningData(lightningTimeList.last);
    }
  }

  Future<void> _loadMapImages() async {
    await _mapController.addImage("cross", await loadImageFromAsset("assets/cross.png"));
    await _mapController.addImage("circle", await loadImageFromAsset("assets/circle.png"));
  }

  Future<void> _loadLightningData(String time) async {
    List<Lightning> lightningData = await ExpTech().getLightning(time);
    lightningDataList = lightningData
        .map((lightning) => LightningData(
      latitude: lightning.loc.lat,
      longitude: lightning.loc.lng,
      type: lightning.type,
      time: lightning.time,
    ))
        .toList();

    await _addLightningMarkers();
  }

  Future<void> _addLightningMarkers() async {
    final features = lightningDataList
        .map((data) => {
      "type": "Feature",
      "properties": {
        "type": data.type,
        "time": data.time,
      },
      "geometry": {
        "type": "Point",
        "coordinates": [data.longitude, data.latitude]
      }
    })
        .toList();

    await _mapController.setGeoJsonSource("lightning-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("lightning-markers");
    await _mapController.addLayer(
      "lightning-data",
      "lightning-markers",
      SymbolLayerProperties(
        iconImage: [
          Expressions.match,
          ["get", "type"],
          1,
          "cross",
          "circle",
        ],
        iconSize: 0.5,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconColor: [
          Expressions.match,
          ["get", "type"],
          1,
          "#FF0000", // 紅色for對地閃電
          "#FFA500", // 橙色for雲間閃電
        ],
      ),
    );
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('閃電圖例', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildLegendItem(Icons.add, Colors.red, '對地閃電'),
          _buildLegendItem(Icons.circle, Colors.orange, '雲間閃電'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(
          onMapCreated: _initMap,
          onStyleLoadedCallback: _loadMap,
          minMaxZoomPreference: const MinMaxZoomPreference(3, 12),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Material(
            color: Theme.of(context).colorScheme.secondary,
            elevation: 4.0,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggleLegend,
              child: Tooltip(
                message: '圖例',
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: Icon(
                    _showLegend ? Icons.close : Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (lightningTimeList.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: lightningTimeList,
              onTimeExpanded: () {
                _showLegend = false;
                setState(() {});
              },
              onTimeSelected: (time) async {
                await _loadLightningData(time);
                setState(() {});
              },
            ),
          ),
        if (_showLegend)
          Positioned(
            left: 6,
            bottom: 50,
            child: _buildLegend(),
          ),
      ],
    );
  }
}