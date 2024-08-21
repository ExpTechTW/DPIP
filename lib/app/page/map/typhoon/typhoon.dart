import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:math' show asin, atan2, cos, pi, sin;

import '../../../../widget/map/map.dart';

class TyphoonData {
  final int year;
  final String cwaTdNo;
  final List<TyphoonFix> analysisFixes;
  final List<TyphoonFix> forecastFixes;

  TyphoonData({
    required this.year,
    required this.cwaTdNo,
    required this.analysisFixes,
    required this.forecastFixes,
  });

  factory TyphoonData.fromJson(Map<String, dynamic> json) {
    final tropicalCyclone = json['tropicalCyclones']['tropicalCyclone'][0];
    return TyphoonData(
      year: tropicalCyclone['year'],
      cwaTdNo: tropicalCyclone['cwaTdNo'],
      analysisFixes: (tropicalCyclone['analysisData']['fix'] as List)
          .map((fix) => TyphoonFix.fromJson(fix))
          .toList(),
      forecastFixes: (tropicalCyclone['forecastData']['fix'] as List)
          .map((fix) => TyphoonFix.fromJson(fix))
          .toList(),
    );
  }

  TyphoonFix get currentFix => analysisFixes.last;

  List<LatLng> get path {
    return [...analysisFixes, ...forecastFixes].map((fix) => fix.coordinate).toList();
  }
}


class TyphoonFix {
  final DateTime fixTime;
  final LatLng coordinate;
  final double maxWindSpeed;
  final double maxGustSpeed;
  final int pressure;
  final String? movingSpeed;
  final String? movingDirection;
  final List<String> movingPrediction;
  final double? radiusOf70PercentProbability;
  final double? circleOf15MsRadius;

  TyphoonFix({
    required this.fixTime,
    required this.coordinate,
    required this.maxWindSpeed,
    required this.maxGustSpeed,
    required this.pressure,
    this.movingSpeed,
    this.movingDirection,
    required this.movingPrediction,
    this.radiusOf70PercentProbability,
    this.circleOf15MsRadius,
  });

  factory TyphoonFix.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinate'].split(',');
    return TyphoonFix(
      fixTime: DateTime.parse(json['fixTime'] ?? json['initTime']),
      coordinate: LatLng(double.parse(coordinates[1]), double.parse(coordinates[0])),
      maxWindSpeed: double.parse(json['maxWindSpeed']),
      maxGustSpeed: double.parse(json['maxGustSpeed']),
      pressure: int.parse(json['pressure']),
      movingSpeed: json['movingSpeed'],
      movingDirection: json['movingDirection'],
      movingPrediction: (json['movingPrediction'] as List?)
          ?.map((pred) => pred['value'].toString())
          .toList() ??
          [],
      radiusOf70PercentProbability: json['radiusOf70PercentProbability'] != null
          ? double.parse(json['radiusOf70PercentProbability'])
          : null,
      circleOf15MsRadius: json['circleOf15Ms']?['radius'] != null
          ? double.parse(json['circleOf15Ms']['radius'])
          : null,
    );
  }
}

class TyphoonMap extends StatefulWidget {
  const TyphoonMap({Key? key}) : super(key: key);

  @override
  _TyphoonMapState createState() => _TyphoonMapState();
}

class _TyphoonMapState extends State<TyphoonMap> {
  late MapLibreMapController _mapController;
  TyphoonData? typhoonData;

  @override
  void initState() {
    super.initState();
    _loadTyphoonData();
  }

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _loadMap() async {
    await _mapController.addSource(
      "typhoon-data",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );

    await _setupTyphoonLayers();
    if (typhoonData != null) {
      _updateTyphoonData(typhoonData!);
    }
  }

  Future<void> _loadTyphoonData() async {
    // 這裡應該是從API獲取數據，現在我們直接使用提供的JSON
    const jsonString = '''
    {
      "dataid": "C0034-005",
      "note": "西北太平洋地區及南海目前所有活動中熱帶氣旋之資訊-熱帶性低氣壓及颱風過去、現在及未來預報之資訊",
      "tropicalCyclones": {
        "tropicalCyclone": [
          {
            "year": 2024,
            "analysisData": {
              "fix": [
                {
                  "fixTime": "2024-08-21T08:00:00+08:00",
                  "coordinate": "144.0,15.7",
                  "maxWindSpeed": "15",
                  "maxGustSpeed": "23",
                  "pressure": "1006",
                  "movingPrediction": []
                },
                {
                  "fixTime": "2024-08-21T14:00:00+08:00",
                  "coordinate": "143.6,16.3",
                  "maxWindSpeed": "15",
                  "maxGustSpeed": "23",
                  "pressure": "1006",
                  "movingSpeed": "13",
                  "movingDirection": "NNW",
                  "movingPrediction": [
                    {
                      "value": "以每小時9公里速度，向西北西進行",
                      "lang": "zh-hant"
                    },
                    {
                      "value": "WNW 9 KM/HR",
                      "lang": "en-us"
                    }
                  ]
                }
              ]
            },
            "forecastData": {
              "fix": [
                {
                  "initTime": "2024-08-21T14:00:00+08:00",
                  "tau": "24",
                  "coordinate": "141.7,17.2",
                  "maxWindSpeed": "18",
                  "maxGustSpeed": "25",
                  "pressure": "1000",
                  "movingSpeed": "8",
                  "movingDirection": "WNW",
                  "circleOf15Ms": {
                    "radius": "80"
                  },
                  "radiusOf70PercentProbability": "140"
                },
                {
                  "initTime": "2024-08-21T14:00:00+08:00",
                  "tau": "48",
                  "coordinate": "141.1,18.1",
                  "maxWindSpeed": "25",
                  "maxGustSpeed": "33",
                  "pressure": "988",
                  "movingSpeed": "6",
                  "movingDirection": "NNW",
                  "circleOf15Ms": {
                    "radius": "120"
                  },
                  "radiusOf70PercentProbability": "230"
                }
              ]
            },
            "cwaTdNo": "11"
          }
        ]
      }
    }
    ''';

    final decodedJson = json.decode(jsonString);
    typhoonData = TyphoonData.fromJson(decodedJson);
    setState(() {});

    if (_mapController != null) {
      _updateTyphoonData(typhoonData!);
    }
  }

  Future<void> _setupTyphoonLayers() async {
    // 颱風當前位置
    await _mapController.addLayer(
      "typhoon-data",
      "typhoon-current",
      const CircleLayerProperties(
        circleRadius: 10,
        circleColor: "#FF0000",
        circleOpacity: 0.7,
        circleStrokeWidth: 2,
        circleStrokeColor: "#FFFFFF",
      ),
    );

    // 颱風路徑
    await _mapController.addLayer(
      "typhoon-data",
      "typhoon-path",
      const LineLayerProperties(
        lineColor: "#FF0000",
        lineWidth: 2,
        lineDasharray: [2, 2],
      ),
    );

    // 颱風預測位置
    await _mapController.addLayer(
      "typhoon-data",
      "typhoon-forecast",
      const CircleLayerProperties(
        circleRadius: 6,
        circleColor: "#FFA500",
        circleOpacity: 0.7,
        circleStrokeWidth: 1,
        circleStrokeColor: "#FFFFFF",
      ),
    );

    // 70%機率半徑
    await _mapController.addLayer(
      "typhoon-data",
      "typhoon-70-percent-radius",
      const FillLayerProperties(
        fillColor: "#FF000055",
        fillOutlineColor: "#FF0000",
      ),
    );

    // 15m/s 風速半徑
    await _mapController.addLayer(
      "typhoon-data",
      "typhoon-15ms-radius",
      const FillLayerProperties(
        fillColor: "#FFA50055",
        fillOutlineColor: "#FFA500",
      ),
    );
  }

  List<List<double>> _createCircle(LatLng center, double radiusInKm) {
    const earthRadiusKm = 6371.0;
    final points = <List<double>>[];
    for (var i = 0; i <= 360; i++) {
      final bearing = i * pi / 180;
      final lat1 = center.latitude * pi / 180;
      final lon1 = center.longitude * pi / 180;
      final lat2 = asin(sin(lat1) * cos(radiusInKm / earthRadiusKm) +
          cos(lat1) * sin(radiusInKm / earthRadiusKm) * cos(bearing));
      final lon2 = lon1 +
          atan2(sin(bearing) * sin(radiusInKm / earthRadiusKm) * cos(lat1),
              cos(radiusInKm / earthRadiusKm) - sin(lat1) * sin(lat2));
      points.add([lon2 * 180 / pi, lat2 * 180 / pi]);
    }
    return points;
  }

  Future<void> _updateTyphoonData(TyphoonData typhoon) async {
    final features = [
      // 當前位置
      {
        "type": "Feature",
        "properties": {"type": "current"},
        "geometry": {
          "type": "Point",
          "coordinates": [typhoon.currentFix.coordinate.longitude, typhoon.currentFix.coordinate.latitude],
        },
      },
      // 路徑
      {
        "type": "Feature",
        "properties": {"type": "path"},
        "geometry": {
          "type": "LineString",
          "coordinates": typhoon.path.map((latLng) => [latLng.longitude, latLng.latitude]).toList(),
        },
      },
      // 預測位置
      ...typhoon.forecastFixes.map((fix) => {
        "type": "Feature",
        "properties": {"type": "forecast"},
        "geometry": {
          "type": "Point",
          "coordinates": [fix.coordinate.longitude, fix.coordinate.latitude],
        },
      }),
    ];

    // 添加70%機率半徑
    if (typhoon.currentFix.radiusOf70PercentProbability != null) {
      features.add({
        "type": "Feature",
        "properties": {"type": "70-percent-radius"},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            _createCircle(typhoon.currentFix.coordinate, typhoon.currentFix.radiusOf70PercentProbability! / 2)
          ],
        },
      });
    }

    // 添加15m/s風速半徑
    if (typhoon.currentFix.circleOf15MsRadius != null) {
      features.add({
        "type": "Feature",
        "properties": {"type": "15ms-radius"},
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            _createCircle(typhoon.currentFix.coordinate, typhoon.currentFix.circleOf15MsRadius!)
          ],
        },
      });
    }

    await _mapController.setGeoJsonSource(
      "typhoon-data",
      {
        "type": "FeatureCollection",
        "features": features,
      },
    );

    await _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            typhoon.path.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
            typhoon.path.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            typhoon.path.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
            typhoon.path.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
          ),
        ),
        left: 50,
        top: 50,
        right: 50,
        bottom: 50,
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
        if (typhoonData != null)
          Positioned(
            top: 10,
            right: 10,
            child: TyphoonInfoCard(typhoon: typhoonData!),
          ),
      ],
    );
  }
}

class TyphoonInfoCard extends StatelessWidget {
  final TyphoonData typhoon;

  const TyphoonInfoCard({Key? key, required this.typhoon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentFix = typhoon.currentFix;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('颱風編號: ${typhoon.cwaTdNo}'),
            Text('最大風速: ${currentFix.maxWindSpeed} m/s'),
            Text('最大陣風: ${currentFix.maxGustSpeed} m/s'),
            Text('氣壓: ${currentFix.pressure} hPa'),
            if (currentFix.movingSpeed != null)
              Text('移動速度: ${currentFix.movingSpeed} km/h'),
            if (currentFix.movingDirection != null)
              Text('移動方向: ${currentFix.movingDirection}'),
            if (currentFix.movingPrediction.isNotEmpty)
              Text('移動預測: ${currentFix.movingPrediction.first}'),
            if (currentFix.radiusOf70PercentProbability != null)
              Text('70%機率半徑: ${currentFix.radiusOf70PercentProbability} km'),
            if (currentFix.circleOf15MsRadius != null)
              Text('15m/s風速半徑: ${currentFix.circleOf15MsRadius} km'),
          ],
        ),
      ),
    );
  }
}