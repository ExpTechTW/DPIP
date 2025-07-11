import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TyphoonMap extends StatefulWidget {
  const TyphoonMap({super.key});

  @override
  State<TyphoonMap> createState() => _TyphoonMapState();
}

class _TyphoonMapState extends State<TyphoonMap> {
  late MapLibreMapController _mapController;
  List typhoonImagesList = [];
  Map<String, dynamic> typhoonData = {};
  List<String> typhoonList = [];
  int selectedTyphoonId = -1;
  List<String> sourceList = [];
  List<String> layerList = [];
  List<String> typhoon_name_list = [];
  List<int> typhoon_id_list = [];
  String selectedTimestamp = '';
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    try {
      typhoonImagesList = await ExpTech().getTyphoonImagesList();
      typhoonData = await ExpTech().getTyphoonGeojson();

      if (Platform.isIOS && (Global.preference.getBool('auto-location') ?? false)) {
        await getSavedLocation();
      }
      userLat = Global.preference.getDouble('user-lat') ?? 0.0;
      userLon = Global.preference.getDouble('user-lon') ?? 0.0;

      isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

      if (isUserLocationValid) {
        await _mapController.addSource(
          'markers-geojson',
          const GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': []}),
        );
        await _mapController.setGeoJsonSource('markers-geojson', {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {
                'coordinates': [userLon, userLat],
                'type': 'Point',
              },
            },
          ],
        });
      }

      await _addUserLocationMarker();

      _addTransparentLayerFromDataset();

      _loadTyphoonLayers();

      setState(() {});
    } catch (e) {
      TalkerManager.instance.error('加載颱風列表時出錯: $e');
    }
  }

  Future<void> _addUserLocationMarker() async {
    if (isUserLocationValid) {
      await _mapController.removeLayer('markers');
      await _mapController.addLayer(
        'markers-geojson',
        'markers',
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
  }

  Future<void> _loadTyphoonLayers() async {
    await _mapController.addSource('typhoon-geojson', GeojsonSourceProperties(data: typhoonData));

    await _mapController.addLayer(
      'typhoon-geojson',
      'typhoon-path',
      const LineLayerProperties(
        lineColor: [
          'match',
          [
            'get',
            'color',
            ['properties'],
          ],
          0, '#1565C0', // 藍色
          1, '#4CAF50', // 綠色
          2, '#FFC107', // 黃色
          3, '#FF5722', // 橙色
          '#757575', // 默認灰色
        ],
        lineWidth: 2,
      ),
    );

    await _mapController.addLayer(
      'typhoon-geojson',
      'typhoon-points',
      const CircleLayerProperties(
        circleRadius: 3,
        circleColor: [
          'match',
          [
            'get',
            'color',
            ['properties'],
          ],
          0,
          '#1565C0',
          1,
          '#4CAF50',
          2,
          '#FFC107',
          3,
          '#FF5722',
          '#757575',
        ],
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
      filter: [
        'all',
        [
          '!=',
          [
            'get',
            'forecast',
            [
              'get',
              'type',
              ['properties'],
            ],
          ],
          true,
        ],
      ],
    );

    // 添加風圈圖層（只顯示第一個 type.forecast 為 true 的點）
    await _mapController.addLayer(
      'typhoon-geojson',
      'typhoon-wind-circle',
      const FillLayerProperties(fillColor: 'rgba(255, 0, 0, 0.1)', fillOutlineColor: 'rgba(255, 0, 0, 0.6)'),
      filter: [
        'all',
        [
          '==',
          ['geometry-type'],
          'Polygon',
        ],
        [
          '==',
          [
            'get',
            'type',
            ['properties'],
          ],
          'wind-circle',
        ],
        [
          '==',
          [
            'get',
            'forecast',
            [
              'get',
              'type',
              ['properties'],
            ],
          ],
          true,
        ],
        [
          '==',
          [
            'get',
            'tau',
            [
              'get',
              'type',
              ['properties'],
            ],
          ],
          0,
        ],
      ],
    );
  }

  void _addTransparentLayerFromDataset() {
    final List<double> lonRange = [110, 150];
    final List<double> latRange = [10, 32];

    final bounds = LatLngBounds(
      southwest: LatLng(latRange[0], lonRange[0]),
      northeast: LatLng(latRange[1], lonRange[1]),
    );

    _mapController.addSource(
      'radarOverlaySource',
      ImageSourceProperties(
        url: 'https://api-1.exptech.dev/api/v1/meteor/typhoon/images/${typhoonImagesList.last}',
        coordinates: [
          [bounds.southwest.longitude, bounds.northeast.latitude],
          [bounds.northeast.longitude, bounds.northeast.latitude],
          [bounds.northeast.longitude, bounds.southwest.latitude],
          [bounds.southwest.longitude, bounds.southwest.latitude],
        ],
      ),
    );

    _mapController.addLayer('radarOverlaySource', 'radarOverlayLayer', const RasterLayerProperties(rasterOpacity: 1));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
      ],
    );
  }
}
