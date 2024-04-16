import 'dart:io';
import 'dart:math';

import 'package:dpip/global.dart';
import 'package:dpip/model/earthquake_report.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/widget/drag_handle.dart';
import 'package:dpip/widget/report/image_field.dart';
import 'package:dpip/widget/report/intensity_capsule.dart';
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

class _ReportPage extends State<ReportPage> with SingleTickerProviderStateMixin {
  final mapController = MapController();
  final _sheet = GlobalKey();
  final _sheetController = DraggableScrollableController();

  late AnimationController _animationController;
  final borderRadius = BorderRadiusTween(
    begin: const BorderRadius.vertical(top: Radius.circular(24)),
    end: BorderRadius.zero,
  );

  List<Widget> maxIntensities = [];
  final List<Marker> markers = [];
  late EarthquakeReport report;

  DraggableScrollableSheet get sheet => (_sheet.currentWidget as DraggableScrollableSheet);

  int randomNum(int max) {
    return Random().nextInt(max) + 1;
  }

  void fetchFullReport() async {
    final data = await Global.api.getReport(widget.report.id);

    setState(() => report = data);
    initMapMarkers();
    fillIntensityCapsule();
    setState(() {});
  }

  initMapMarkers() {
    final points = <LatLng>[LatLng(report.lat, report.lon)];
    final list = report.list.entries.expand((city) => city.value.town.entries.map((town) => town.value)).toList();

    list.sort((a, b) => a.intensity - b.intensity);

    for (var station in list) {
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
    }

    markers.add(
      Marker(
        height: 42,
        width: 42,
        point: LatLng(report.lat, report.lon),
        child: const Image(
          image: AssetImage("assets/cross.png"),
        ),
      ),
    );

    mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 192),
    ));
  }

  fillIntensityCapsule() {
    List<Widget> cityList = [];
    for (var city in report.list.entries) {
      List<Widget> townList = [];
      for (var town in city.value.town.entries) {
        townList.add(IntensityCapsule(townName: town.key, intensity: town.value.intensity));
      }

      cityList.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              city.key,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: townList,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    maxIntensities = cityList;
  }

  @override
  void initState() {
    super.initState();
    fetchFullReport();

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
          middle: Text(widget.report.hasNumber ? "第 ${widget.report.number} 號" : "小區域有感地震"),
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
                  maxZoom: 12,
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
                                      Text(widget.report.hasNumber ? "第 ${widget.report.number} 號" : "小區域有感地震"),
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
                                  Column(children: maxIntensities),
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
          title: Text(widget.report.hasNumber ? "第 ${widget.report.number} 號" : "小區域有感地震"),
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
                  maxZoom: 12,
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
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                            TZDateTime.fromMillisecondsSinceEpoch(
                                              getLocation("Asia/Taipei"),
                                              widget.report.time,
                                            ),
                                          ),
                                          style: const TextStyle(fontSize: 16),
                                        ),
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
                                    Column(children: maxIntensities),
                                  ],
                                ),
                              ),
                              ImageField(
                                title: "地震報告圖",
                                heroTag: "report_image_${widget.report.id}",
                                aspectRatio: 4 / 3,
                                imageUrl: widget.report.reportImageUrl,
                                imageName: widget.report.reportImageName,
                              ),
                              if (widget.report.hasNumber)
                                ImageField(
                                  title: "震度圖",
                                  heroTag: "intensity_map_image_${widget.report.id}",
                                  aspectRatio: 2334 / 2977,
                                  imageUrl: widget.report.intensityMapImageUrl!,
                                  imageName: widget.report.intensityMapImageName!,
                                ),
                              if (widget.report.hasNumber)
                                ImageField(
                                  title: "最大地動加速度圖",
                                  heroTag: "pga_map_image_${widget.report.id}",
                                  aspectRatio: 2334 / 2977,
                                  imageUrl: widget.report.pgaMapImageUrl!,
                                  imageName: widget.report.pgaMapImageName!,
                                ),
                              if (widget.report.hasNumber)
                                ImageField(
                                  title: "最大地動速度圖",
                                  heroTag: "pgv_map_image_${widget.report.id}",
                                  aspectRatio: 2334 / 2977,
                                  imageUrl: widget.report.pgvMapImageUrl!,
                                  imageName: widget.report.pgvMapImageName!,
                                ),
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
