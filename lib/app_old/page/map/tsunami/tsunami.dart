import "dart:async";
import "dart:io";

import "package:flutter/material.dart";

import "package:intl/intl.dart";
import "package:maplibre_gl/maplibre_gl.dart";
import "package:timezone/timezone.dart" as tz;

import "package:dpip/api/exptech.dart";
import "package:dpip/api/model/tsunami/tsunami.dart";
import "package:dpip/api/model/tsunami/tsunami_actual.dart";
import "package:dpip/api/model/tsunami/tsunami_estimate.dart";
import "package:dpip/app_old/page/map/tsunami/tsunami_estimate_list.dart";
import "package:dpip/app_old/page/map/tsunami/tsunami_observed_list.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/map_utils.dart";
import "package:dpip/widgets/map/map.dart";

class TsunamiMap extends StatefulWidget {
  const TsunamiMap({super.key});

  @override
  State<TsunamiMap> createState() => _TsunamiMapState();
}

class _TsunamiMapState extends State<TsunamiMap> {
  late MapLibreMapController _mapController;
  Timer? _blinkTimer;
  Tsunami? tsunami;
  String tsunamiStatus = "";
  int _isTsunamiVisible = 0;
  String _tsunami_id = "";
  int _tsunami_serial = 0;
  String? _selectedOption;
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
    await loadCrossImage(_mapController);
  }

  void _loadMap() async {
    await refreshTsunami();
    await _mapController.addSource(
      "tsunami-data",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );

    if (tsunami != null) {
      await addTsunamiObservationPoints(tsunami!);
    }

    final isDark = context.theme.brightness == Brightness.dark;

    await _loadMapImages(isDark);

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (isUserLocationValid) {
      await _addUserLocationMarker();
    }

    setState(() {});
  }

  String heightToColor(int height) {
    Color color;
    if (height >= 2) {
      color = const Color(0xFFE543FF);
    } else if (height == 1) {
      color = const Color(0xFFC90000);
    } else {
      color = const Color(0xFFFFC900);
    }
    return "#${color.value.toRadixString(16).padLeft(8, "0").substring(2)}";
  }

  DateTime _convertTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> addTsunamiObservationPoints(Tsunami tsunami) async {
    await _mapController.removeLayer("tsunami-actual-circles");
    await _mapController.removeLayer("tsunami-actual-labels");
    _blinkTimer?.cancel();
    await _mapController.setLayerProperties("tsunami", const LineLayerProperties(lineOpacity: 0));
    if (tsunami.info.type == "estimate") {
      Map<String, String> area_color = {};
      tsunami.info.data.forEach((station) {
        var estimateStation = station as TsunamiEstimate;
        area_color[estimateStation.area] = heightToColor(estimateStation.waveHeight);
      });

      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!mounted) return;
        await _mapController.setLayerProperties(
          "tsunami",
          LineLayerProperties(
            lineColor: [
              "match",
              ["get", "AREANAME"],
              ...area_color.entries.expand((entry) => [entry.key, entry.value]),
              "#000000",
            ],
            lineOpacity: (_isTsunamiVisible < 6) ? 1 : 0,
          ),
        );
        _isTsunamiVisible++;
        if (_isTsunamiVisible >= 8) _isTsunamiVisible = 0;
      });
    } else {
      final features =
          tsunami.info.data.map((station) {
            var actualStation = station as TsunamiActual;
            return {
              "type": "Feature",
              "properties": {
                "name": actualStation.name,
                "id": actualStation.id,
                "waveHeight": actualStation.waveHeight,
                "arrivalTime": DateFormat("MM/dd HH:mm").format(_convertTimestamp(actualStation.arrivalTime)),
              },
              "geometry": {
                "type": "Point",
                "coordinates": [actualStation.lon ?? 0, actualStation.lat ?? 0],
              },
            };
          }).toList();

      await _mapController.setGeoJsonSource("tsunami-data", {"type": "FeatureCollection", "features": features});

      await _mapController.addLayer(
        "tsunami-data",
        "tsunami-actual-circles",
        const CircleLayerProperties(
          circleRadius: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            7,
            8,
            12,
            18,
          ],
          circleColor: [
            Expressions.step,
            [Expressions.get, "waveHeight"],
            "#606060",
            30,
            "#FFC900",
            100,
            "#C90000",
            300,
            "#E543FF",
          ],
          circleOpacity: 1,
          circleStrokeWidth: 0.2,
          circleStrokeColor: "#000000",
          circleStrokeOpacity: 0.7,
        ),
      );

      await _mapController.addSymbolLayer(
        "tsunami-data",
        "tsunami-actual-labels",
        SymbolLayerProperties(
          textField: [
            Expressions.concat,
            ["get", "name"],
            "\n",
            ["get", "arrivalTime"],
            "\n",
            ["get", "waveHeight"],
            "cm\n${context.i18n.monitor_arrival}",
          ],
          textSize: 12,
          textColor: "#ffffff",
          textHaloColor: "#000000",
          textHaloWidth: 1,
          textFont: ["Noto Sans Regular"],
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
      "markers-geojson",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );
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
        iconImage: [
          Expressions.match,
          [Expressions.get, "cross"],
          1,
          "cross",
          "gps",
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
    List markers_features = [];
    final tsunami = this.tsunami;
    if (tsunami != null) {
      markers_features.add({
        "type": "Feature",
        "properties": {"cross": 1},
        "geometry": {
          "coordinates": [tsunami.eq.lon, tsunami.eq.lat],
          "type": "Point",
        },
      });
    }
    markers_features.add({
      "type": "Feature",
      "properties": {},
      "geometry": {
        "coordinates": [userLon, userLat],
        "type": "Point",
      },
    });
    await _mapController.setGeoJsonSource("markers-geojson", {
      "type": "FeatureCollection",
      "features": markers_features,
    });
  }

  Future<Tsunami?> refreshTsunami() async {
    var idList = await ExpTech().getTsunamiList();
    var id = "";
    if (idList.isNotEmpty) {
      id = idList.first;
      _tsunami_id = id.split("-")[0];
      _tsunami_serial = int.parse(id.split("-")[1]);
      tsunami = await ExpTech().getTsunami(id);
      (tsunami?.status == 0)
          ? tsunamiStatus = context.i18n.tsunami_publish
          : (tsunami?.status == 1)
          ? tsunamiStatus = context.i18n.tsunami_renew
          : tsunamiStatus = context.i18n.tsunami_relieve;

      List<String> options = generateTsunamiOptions();
      if (options.isNotEmpty && _selectedOption == null) {
        _selectedOption = options.last;
      }
    }
    return tsunami;
  }

  String convertTimestamp(int timestamp) {
    var location = tz.getLocation("Asia/Taipei");
    DateTime dateTime = tz.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);

    DateFormat formatter = DateFormat("yyyy/MM/dd HH:mm");
    String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }

  String getTime() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat("yyyy/MM/dd HH:mm");
    String formattedDate = formatter.format(now);
    return (formattedDate);
  }

  String convertLatLon(double lat, double lon) {
    var latFormat = "";
    var lonFormat = "";
    if (lat > 90) {
      lat = lat - 180;
    }
    if (lon > 180) {
      lat = lat - 360;
    }
    if (lat < 0) {
      latFormat = context.i18n.south_latitude(lat.abs().toString());
    } else {
      latFormat = context.i18n.north_latitude(lat.toString());
    }
    if (lon < 0) {
      lonFormat = context.i18n.west_longitude(lon.abs().toString());
    } else {
      lonFormat = context.i18n.east_longitude(lon.toString());
    }
    return "$latFormat　$lonFormat";
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  List<String> generateTsunamiOptions() {
    List<String> options = [];
    for (int i = 1; i <= _tsunami_serial; i++) {
      options.add("$_tsunami_id-$i");
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.16;
    List<String> tsunamiOptions = generateTsunamiOptions();

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
              return Container(
                color: context.colors.surface.withOpacity(0.9),
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
                            color: context.colors.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child:
                          tsunami == null
                              ? Container()
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tsunami == null
                                                  ? context.i18n.no_tsunami_information
                                                  : context.i18n.tsunami_warning,
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (tsunami != null)
                                              Text(
                                                context.i18n.tsunami_number(
                                                  tsunami?.id.toString() ?? '',
                                                  tsunami?.serial.toString() ?? '',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.colors.onSurface.withOpacity(0.8),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tsunami != null
                                                  ? "${convertTimestamp(tsunami!.time)} $tsunamiStatus"
                                                  : "${getTime()} 更新",
                                              style: TextStyle(fontSize: 14, color: context.colors.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (tsunamiOptions.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: context.colors.surface,
                                            boxShadow: [
                                              BoxShadow(
                                                color: context.colors.onSurface.withOpacity(0.1),
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
                                              tsunami = await ExpTech().getTsunami(newValue);
                                              tsunamiStatus =
                                                  tsunami?.status == 0
                                                      ? context.i18n.tsunami_publish
                                                      : tsunami?.status == 1
                                                      ? context.i18n.tsunami_renew
                                                      : context.i18n.tsunami_relieve;
                                              if (tsunami != null) {
                                                await addTsunamiObservationPoints(tsunami!);
                                              }
                                              setState(() {});
                                            },
                                            items:
                                                tsunamiOptions.reversed.map<DropdownMenuItem<String>>((String value) {
                                                  return DropdownMenuItem<String>(value: value, child: Text(value));
                                                }).toList(),
                                            style: TextStyle(
                                              color: context.colors.onSurface,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            icon: Icon(Icons.arrow_drop_down, color: context.colors.onSurface),
                                            underline: const SizedBox(),
                                            dropdownColor: context.colors.surface,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  tsunami != null
                                      ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${tsunami?.content}",
                                            style: TextStyle(fontSize: 18, color: context.colors.onSurface),
                                          ),
                                          const SizedBox(height: 20),
                                          tsunami?.info.type == "estimate"
                                              ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.i18n.estimated_time_wave,
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TsunamiEstimateList(tsunamiList: tsunami!.info.data),
                                                ],
                                              )
                                              : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.i18n.observing_tsunamis,
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TsunamiObservedList(tsunamiList: tsunami!.info.data),
                                                ],
                                              ),
                                          const SizedBox(height: 15),
                                          Text(
                                            context.i18n.eew_info_sound_title,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                context.i18n.occurrence_time,
                                                style: TextStyle(fontSize: 18, color: context.colors.onSurface),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                convertTimestamp(tsunami!.eq.time),
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                context.i18n.report_location,
                                                style: TextStyle(fontSize: 18, color: context.colors.onSurface),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tsunami!.eq.loc,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    convertLatLon(tsunami!.eq.lat, tsunami!.eq.lon),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onSurface,
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
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      context.i18n.scale,
                                                      style: TextStyle(fontSize: 18, color: context.colors.onSurface),
                                                    ),
                                                    Text(
                                                      "${tsunami!.eq.mag}",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.colors.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      context.i18n.depth,
                                                      style: TextStyle(fontSize: 18, color: context.colors.onSurface),
                                                    ),
                                                    Text(
                                                      "${tsunami!.eq.depth}km",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.colors.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                      : Container(),
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
