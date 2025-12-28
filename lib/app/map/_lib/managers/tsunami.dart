import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/tsunami/tsunami.dart';
import 'package:dpip/api/model/tsunami/tsunami_actual.dart';
import 'package:dpip/api/model/tsunami/tsunami_estimate.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app_old/page/map/tsunami/tsunami_estimate_list.dart';
import 'package:dpip/app_old/page/map/tsunami/tsunami_observed_list.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TsunamiMapLayerManager extends MapLayerManager {
  TsunamiMapLayerManager(super.context, super.controller);

  final currentTsunami = ValueNotifier(null);
  final isLoading = ValueNotifier<bool>(false);

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      final sourceId = MapSourceIds.tsunami(currentTsunami.value);
      final layerId = MapLayerIds.tsunami(currentTsunami.value);

      final isSourceExists = (await controller.getSourceIds()).contains(
        sourceId,
      );
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        TalkerManager.instance.info('Added Source "$sourceId"');

        if (!context.mounted) return;
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('TsunamiMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.tsunami(currentTsunami.value);

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('TsunamiMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.tsunami(currentTsunami.value);

    try {
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('TsunamiMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.tsunami(currentTsunami.value);
      final sourceId = MapSourceIds.tsunami(currentTsunami.value);

      await controller.removeLayer(layerId);
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('TsunamiMapLayerManager.dispose', e, s);
    }
    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => TsunamiMapLayerSheet(manager: this);
}

class TsunamiMapLayerSheet extends StatefulWidget {
  final TsunamiMapLayerManager manager;

  const TsunamiMapLayerSheet({super.key, required this.manager});

  @override
  State<TsunamiMapLayerSheet> createState() => _TsunamiMapLayerSheetState();
}

class _TsunamiMapLayerSheetState extends State<TsunamiMapLayerSheet> {
  late MapLibreMapController _mapController;
  Timer? _blinkTimer;
  Tsunami? tsunami;
  String tsunamiStatus = '';
  int _isTsunamiVisible = 0;
  String _tsunami_id = '';
  int _tsunami_serial = 0;
  String? _selectedOption;
  double userLat = 0;
  double userLon = 0;

  Future<void> _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    await refreshTsunami();
    await _mapController.addSource(
      'tsunami-data',
      const GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    if (tsunami != null) {
      await addTsunamiObservationPoints(tsunami!);
    }

    if (GlobalProviders.location.auto) {
      await updateLocationFromGPS();
    }
    userLat = Global.preference.getDouble('user-lat') ?? 0.0;
    userLon = Global.preference.getDouble('user-lon') ?? 0.0;

    final location = LatLng(userLat, userLon);

    if (location.isValid) {
      await _addUserLocationMarker();
    }

    setState(() {});
  }

  String heightToColor(int height) {
    Color color;
    if (height == 3) {
      color = const Color(0xFFE543FF);
    } else if (height == 2) {
      color = const Color(0xFFC90000);
    } else if (height == 1) {
      color = const Color(0xFFFFC900);
    } else {
      color = const Color(0xFF00AAFF);
    }
    return '#${color.hex}';
  }

  DateTime _convertTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> addTsunamiObservationPoints(Tsunami tsunami) async {
    await _mapController.removeLayer('tsunami-actual-circles');
    await _mapController.removeLayer('tsunami-actual-labels');
    _blinkTimer?.cancel();
    await _mapController.setLayerProperties(
      'tsunami',
      const LineLayerProperties(lineOpacity: 0),
    );
    if (tsunami.info.type == 'estimate') {
      final Map<String, String> areaColor = {};
      for (final station in tsunami.info.data) {
        final estimateStation = station as TsunamiEstimate;
        areaColor[estimateStation.area] = heightToColor(
          estimateStation.waveHeight,
        );
      }

      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        if (!mounted) return;
        await _mapController.setLayerProperties(
          'tsunami',
          LineLayerProperties(
            lineColor: [
              'match',
              ['get', 'AREANAME'],
              ...areaColor.entries.expand((entry) => [entry.key, entry.value]),
              '#000000',
            ],
            lineOpacity: (_isTsunamiVisible < 6) ? 1 : 0,
          ),
        );
        _isTsunamiVisible++;
        if (_isTsunamiVisible >= 8) _isTsunamiVisible = 0;
      });
    } else {
      final features = tsunami.info.data.map((station) {
        final actualStation = station as TsunamiActual;
        return {
          'type': 'Feature',
          'properties': {
            'name': actualStation.name,
            'id': actualStation.id,
            'waveHeight': actualStation.waveHeight,
            'arrivalTime': DateFormat(
              'MM/dd HH:mm',
            ).format(_convertTimestamp(actualStation.arrivalTime)),
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [actualStation.lon ?? 0, actualStation.lat ?? 0],
          },
        };
      }).toList();

      await _mapController.setGeoJsonSource('tsunami-data', {
        'type': 'FeatureCollection',
        'features': features,
      });

      await _mapController.addLayer(
        'tsunami-data',
        'tsunami-actual-circles',
        const CircleLayerProperties(
          circleRadius: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            7,
            8,
            12,
            18,
          ],
          circleColor: [
            Expressions.step,
            [Expressions.get, 'waveHeight'],
            '#00AAFF',
            30,
            '#FFC900',
            100,
            '#C90000',
            300,
            '#E543FF',
          ],
          circleOpacity: 1,
          circleStrokeWidth: 0.2,
          circleStrokeColor: '#000000',
          circleStrokeOpacity: 0.7,
        ),
      );

      await _mapController.addSymbolLayer(
        'tsunami-data',
        'tsunami-actual-labels',
        const SymbolLayerProperties(
          textField: [
            Expressions.concat,
            ['get', 'name'],
            '\n',
            ['get', 'arrivalTime'],
            '\n',
            ['get', 'waveHeight'],
            'cm\n抵達',
          ],
          textSize: 12,
          textColor: '#ffffff',
          textHaloColor: '#000000',
          textHaloWidth: 1,
          textFont: ['Noto Sans TC Bold'],
          textOffset: [
            Expressions.literal,
            [0, 3.5],
          ],
        ),
        minzoom: 7,
      );
    }
  }

  Future<void> _addUserLocationMarker() async {
    await _mapController.addSource(
      'markers-geojson',
      const GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );
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
        iconImage: [
          Expressions.match,
          [Expressions.get, 'cross'],
          1,
          'cross',
          'gps',
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
    final List markersFeatures = [];
    final tsunami = this.tsunami;
    if (tsunami != null) {
      markersFeatures.add({
        'type': 'Feature',
        'properties': {'cross': 1},
        'geometry': {
          'coordinates': [tsunami.eq.lon, tsunami.eq.lat],
          'type': 'Point',
        },
      });
    }
    markersFeatures.add({
      'type': 'Feature',
      'properties': {},
      'geometry': {
        'coordinates': [userLon, userLat],
        'type': 'Point',
      },
    });
    await _mapController.setGeoJsonSource('markers-geojson', {
      'type': 'FeatureCollection',
      'features': markersFeatures,
    });
  }

  Future<Tsunami?> refreshTsunami() async {
    final idList = await ExpTech().getTsunamiList();
    var id = '';
    if (idList.isNotEmpty) {
      id = idList.first;
      _tsunami_id = id.split('-')[0];
      _tsunami_serial = int.parse(id.split('-')[1]);
      tsunami = await ExpTech().getTsunami(id);
      (tsunami?.status == 0)
          ? tsunamiStatus = '發布'
          : (tsunami?.status == 1)
          ? tsunamiStatus = '更新'
          : tsunamiStatus = '解除';

      final List<String> options = generateTsunamiOptions();
      if (options.isNotEmpty && _selectedOption == null) {
        _selectedOption = options.last;
      }
    }
    return tsunami;
  }

  String getTime() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    final String formattedDate = formatter.format(now);
    return formattedDate;
  }

  String convertLatLon(double latitude, double longitude) {
    double lat = latitude;
    final double lon = longitude;

    var latFormat = '';
    var lonFormat = '';

    if (latitude > 90) lat = latitude - 180;
    if (longitude > 180) lat = latitude - 360;

    if (lat < 0) {
      latFormat = '南緯 ${lat.abs} 度';
    } else {
      latFormat = '北緯 $lat 度';
    }

    if (lon < 0) {
      lonFormat = '西經 ${lon.abs} 度';
    } else {
      lonFormat = '東經 $lon 度';
    }

    return '$latFormat　$lonFormat';
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  List<String> generateTsunamiOptions() {
    final List<String> options = [];
    for (int i = 1; i <= _tsunami_serial; i++) {
      options.add('$_tsunami_id-$i');
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.16;
    final List<String> tsunamiOptions = generateTsunamiOptions();

    return Stack(
      children: [
        DpipMap(
          onMapCreated: _initMap,
          onStyleLoadedCallback: _loadMap,
          minMaxZoomPreference: const MinMaxZoomPreference(3, 12),
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: sheetInitialSize,
            minChildSize: sheetInitialSize,
            snap: true,
            builder: (context, scrollController) {
              return ColoredBox(
                color: context.colors.surface.withValues(alpha: 0.9),
                child: ListView(
                  controller: scrollController,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.colors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: tsunami == null
                          ? Container()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tsunami == null
                                                ? '近期無海嘯資訊'
                                                : '海嘯警報',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (tsunami != null)
                                            Text(
                                              '${tsunami!.id}號 第${tsunami!.serial}報',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: context.colors.onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            tsunami != null
                                                ? '${tsunami!.time.toLocaleDateTimeString(context)} $tsunamiStatus'
                                                : '${getTime()} 更新',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context
                                                  .colors
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (tsunamiOptions.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: context.colors.surface,
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.colors.onSurface
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedOption,
                                          onChanged: (String? newValue) async {
                                            if (newValue == null) return;
                                            _selectedOption = newValue;
                                            tsunami = await ExpTech()
                                                .getTsunami(newValue);
                                            tsunamiStatus = tsunami?.status == 0
                                                ? '發布'
                                                : tsunami?.status == 1
                                                ? '更新'
                                                : '解除';
                                            if (tsunami != null) {
                                              await addTsunamiObservationPoints(
                                                tsunami!,
                                              );
                                            }
                                            setState(() {});
                                          },
                                          items: tsunamiOptions.reversed
                                              .map<DropdownMenuItem<String>>((
                                                String value,
                                              ) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              })
                                              .toList(),
                                          style: TextStyle(
                                            color: context.colors.onSurface,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: context.colors.onSurface,
                                          ),
                                          underline: const SizedBox(),
                                          dropdownColor: context.colors.surface,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                if (tsunami != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${tsunami?.content}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      if (tsunami?.info.type == 'estimate')
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '預估海嘯到達時間及波高',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TsunamiEstimateList(
                                              tsunamiList: tsunami!.info.data,
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '各地觀測到的海嘯',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TsunamiObservedList(
                                              tsunamiList: tsunami!.info.data,
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 15),
                                      Text(
                                        '地震資訊',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '發生時間',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tsunami!.eq.time
                                                .toLocaleDateTimeString(
                                                  context,
                                                ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '位於',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tsunami!.eq.loc,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      context.colors.onSurface,
                                                ),
                                              ),
                                              Text(
                                                convertLatLon(
                                                  tsunami!.eq.lat,
                                                  tsunami!.eq.lon,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      context.colors.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '規模',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: context
                                                        .colors
                                                        .onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  '${tsunami!.eq.mag}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: context
                                                        .colors
                                                        .onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '深度',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: context
                                                        .colors
                                                        .onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  '${tsunami!.eq.depth}km',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: context
                                                        .colors
                                                        .onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Container(),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
