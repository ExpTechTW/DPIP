import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dpip/global.dart';
import 'package:dpip/model/earthquake_report.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/widget/drag_handle.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils.dart';

class ReportPage extends StatefulWidget {
  final PartialEarthquakeReport report;

  const ReportPage({super.key, required this.report});

  @override
  State<ReportPage> createState() => _ReportPage();
}

var earthquakeType = "", level = 0, Lv_str = "";
List<Color> intensity_back = const [
  Color(0xff6B7878),
  Color(0xff1E6EE6),
  Color(0xff32B464),
  Color(0xffFFE05D),
  Color(0xffFFAA13),
  Color(0xffEF700F),
  Color(0xffE60000),
  Color(0xffA00000),
  Color(0xff5D0090),
];

class _ReportPage extends State<ReportPage> with SingleTickerProviderStateMixin {
  final mapController = MapController();
  final _sheet = GlobalKey();
  final _sheetController = DraggableScrollableController();

  late AnimationController _animationController;
  final borderRadius = BorderRadiusTween(
    begin: const BorderRadius.vertical(top: Radius.circular(24)),
    end: BorderRadius.zero,
  );

  final report = Completer<EarthquakeReport>();
  final List<Marker> markers = [];

  DraggableScrollableSheet get sheet => (_sheet.currentWidget as DraggableScrollableSheet);

  int randomNum(int max) {
    return Random().nextInt(max) + 1;
  }

  Future<void> render() {
    return Global.api.getReport(widget.report.id).then((data) {
      report.complete(data);

      earthquakeType = data.getNumber() != null ? "第 ${data.getNumber()!} 號顯著有感地震" : "小區域有感地震";

      var keys = data.list.keys.toList();
      level = data.list[keys[0]]!.intensity;
      Lv_str = intensityToNumberString(level);

      final points = <LatLng>[LatLng(data.lat, data.lon)];

      for (String areaName in data.list.keys) {
        final area = data.list[areaName]!;

        for (String stationName in area.town.keys) {
          final station = data.list[areaName]!.town[stationName]!;

          points.add(LatLng(station.lat, station.lon));

          markers.add(
            Marker(
              height: 20,
              width: 20,
              point: LatLng(station.lat, station.lon),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white,
                  ),
                  color: context.colors.intensity(station.intensity),
                ),
                child: Center(
                  child: Text(
                    intensityToNumberString(station.intensity),
                    style: TextStyle(
                      height: 1,
                      color: context.colors.onIntensity(station.intensity),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );

          markers.add(
            Marker(
              height: 42,
              width: 42,
              point: LatLng(data.lat, data.lon),
              child: const Image(
                image: AssetImage("assets/cross.png"),
              ),
            ),
          );
        }
      }

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 240),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    render();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );

    _sheetController.addListener(() {
      _animationController.animateTo(
        _sheetController.size,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sheetController.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.report.getNumber() != null ? "第 ${widget.report.getNumber()} 號" : "小區域有感地震"),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(23.8, 120.1),
                  initialZoom: 7,
                  minZoom: 7,
                  maxZoom: 9,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchMove | InteractiveFlag.pinchZoom,
                  ),
                  backgroundColor: Colors.transparent,
                  onPointerDown: (event, point) {
                    _sheetController.animateTo(
                      sheet.minChildSize,
                      duration: const Duration(milliseconds: 200),
                      curve: Easing.standard,
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/whes1015/clne7f5m500jd01re1psi1cd2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid2hlczEwMTUiLCJhIjoiY2xuZTRhbmhxMGIzczJtazN5Mzg0M2JscCJ9.BHkuZTYbP7Bg1U9SfLE-Cg",
                  ),
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return DraggableScrollableSheet(
                    key: _sheet,
                    initialChildSize: 160 / constraints.maxHeight,
                    minChildSize: 100 / constraints.maxHeight,
                    maxChildSize: 1,
                    snap: true,
                    snapSizes: [
                      160 / constraints.maxHeight,
                    ],
                    controller: _sheetController,
                    builder: (BuildContext context, ScrollController scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        margin: EdgeInsets.zero,
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const DragHandleDecoration(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.report.getLocation(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(widget.report.getNumber() != null
                                          ? "第 ${widget.report.getNumber()} 號"
                                          : "小區域有感地震"),
                                    ],
                                  ),
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: context.colors.intensity(widget.report.intensity),
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.report.intensity.toString(),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.onIntensity(widget.report.intensity),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  CupertinoButton.filled(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: const Row(
                                      children: [
                                        Icon(CupertinoIcons.globe),
                                        Text("報告頁面"),
                                      ],
                                    ),
                                    onPressed: () {
                                      launchUrl(widget.report.cwaUrl);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.clock),
                              title: const Text("發生時間"),
                              additionalInfo: Text(
                                DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                  TZDateTime.fromMillisecondsSinceEpoch(
                                    getLocation("Asia/Taipei"),
                                    widget.report.time,
                                  ),
                                ),
                              ),
                            ),
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.location_solid),
                              title: const Text("震央地點"),
                              additionalInfo: Text(widget.report.loc.replaceFirst("(", "\n(")),
                            ),
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.map),
                              title: const Text("震央座標"),
                              additionalInfo: Text("${widget.report.lat}ºN ${widget.report.lon}ºE"),
                            ),
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.speedometer),
                              title: const Text("規模"),
                              additionalInfo: Text("M ${widget.report.mag}"),
                            ),
                            CupertinoListTile(
                              leading: const Icon(CupertinoIcons.arrow_down_to_line),
                              title: const Text("深度"),
                              additionalInfo: Text("${widget.report.depth} km"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "各地最大震度",
                                    style: TextStyle(
                                      color: context.colors.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder(
                                    future: report.future,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        List<Widget> city = [];

                                        snapshot.data!.list.forEach(
                                          (cityName, value) {
                                            List<Widget> town = [];

                                            value.town.forEach((townName, value) {
                                              town.add(
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: context.colors.intensity(value.intensity),
                                                    ),
                                                    color: context.colors.intensity(value.intensity).withOpacity(0.08),
                                                  ),
                                                  margin: EdgeInsets.zero,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        height: 30,
                                                        width: 30,
                                                        decoration: BoxDecoration(
                                                          color: context.colors.intensity(value.intensity),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            intensityToNumberString(value.intensity),
                                                            style: TextStyle(
                                                                color: context.colors.onIntensity(value.intensity),
                                                                height: 1,
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                                                        child: Text(
                                                          townName,
                                                          style: TextStyle(
                                                            color: CupertinoColors.label.resolveFrom(context),
                                                            height: 1,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });

                                            city.add(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    cityName,
                                                    style: TextStyle(
                                                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: town,
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        return Column(
                                          children: city,
                                        );
                                      } else {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.report.getNumber() != null ? "第 ${widget.report.getNumber()} 號" : "小區域有感地震"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(23.8, 120.1),
                  initialZoom: 7,
                  minZoom: 7,
                  maxZoom: 9,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchMove | InteractiveFlag.pinchZoom,
                  ),
                  backgroundColor: Colors.transparent,
                  onPointerDown: (event, point) {
                    _sheetController.animateTo(
                      sheet.minChildSize,
                      duration: const Duration(milliseconds: 200),
                      curve: Easing.standard,
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://api.mapbox.com/styles/v1/whes1015/clne7f5m500jd01re1psi1cd2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid2hlczEwMTUiLCJhIjoiY2xuZTRhbmhxMGIzczJtazN5Mzg0M2JscCJ9.BHkuZTYbP7Bg1U9SfLE-Cg",
                  ),
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),
              LayoutBuilder(builder: (context, constraints) {
                return DraggableScrollableSheet(
                  key: _sheet,
                  initialChildSize: 160 / constraints.maxHeight,
                  minChildSize: 100 / constraints.maxHeight,
                  maxChildSize: 1.0,
                  snap: true,
                  snapSizes: [
                    160 / constraints.maxHeight,
                  ],
                  controller: _sheetController,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Card(
                          elevation: 3,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: borderRadius.evaluate(_animationController)!,
                          ),
                          margin: EdgeInsets.zero,
                          child: ListView(
                            controller: scrollController,
                            children: [
                              const DragHandleDecoration(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.report.getLocation(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(widget.report.getNumber() != null
                                            ? "第 ${widget.report.getNumber()} 號"
                                            : "小區域有感地震"),
                                      ],
                                    ),
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12.0),
                                        color: context.colors.intensity(widget.report.intensity),
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.report.intensity.toString(),
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.onIntensity(widget.report.intensity),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 20,
                                ),
                                child: Wrap(
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.open_in_new_rounded),
                                      label: const Text("報告頁面"),
                                      elevation: 3,
                                      shadowColor: Colors.transparent,
                                      onPressed: () {
                                        launchUrl(widget.report.cwaUrl);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.schedule_rounded),
                                title: const Text("發生時間"),
                                subtitle: Text(
                                  DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      widget.report.time,
                                    ),
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.pin_drop_rounded),
                                title: const Text("震央地點"),
                                subtitle: Text(widget.report.loc.replaceFirst("(", "\n(")),
                              ),
                              ListTile(
                                leading: const Icon(Icons.gps_fixed_rounded),
                                title: const Text("震央座標"),
                                subtitle: Text("${widget.report.lat}ºN ${widget.report.lon}ºE"),
                              ),
                              Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      child: ListTile(
                                        leading: const Icon(Icons.speed_rounded),
                                        title: const Text("規模"),
                                        subtitle: Text("M ${widget.report.mag}"),
                                      )),
                                  Flexible(
                                    flex: 1,
                                    child: ListTile(
                                      leading: const Icon(Icons.keyboard_double_arrow_down_rounded),
                                      title: const Text("深度"),
                                      subtitle: Text("${widget.report.depth} km"),
                                    ),
                                  )
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "各地最大震度",
                                      style: TextStyle(
                                        color: context.colors.onSurface,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder(
                                      future: report.future,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          List<Widget> city = [];

                                          snapshot.data!.list.forEach(
                                            (cityName, value) {
                                              List<Widget> town = [];

                                              value.town.forEach((townName, value) {
                                                town.add(
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: context.colors.intensity(value.intensity),
                                                      ),
                                                      color:
                                                          context.colors.intensity(value.intensity).withOpacity(0.08),
                                                    ),
                                                    margin: EdgeInsets.zero,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          height: 30,
                                                          width: 30,
                                                          decoration: BoxDecoration(
                                                            color: context.colors.intensity(value.intensity),
                                                            borderRadius: BorderRadius.circular(16),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              intensityToNumberString(value.intensity),
                                                              style: TextStyle(
                                                                  color: context.colors.onIntensity(value.intensity),
                                                                  height: 1,
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                                                          child: Text(
                                                            townName,
                                                            style: TextStyle(
                                                              color: context.colors.onSurfaceVariant.harmonizeWith(
                                                                  context.colors.intensity(value.intensity)),
                                                              height: 1,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              });

                                              city.add(
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Text(
                                                      cityName,
                                                      style: TextStyle(color: context.colors.outline),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: town,
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                ),
                                              );
                                            },
                                          );

                                          return Column(
                                            children: city,
                                          );
                                        } else {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ],
          ),
        ),
      );
    }
  }
}
