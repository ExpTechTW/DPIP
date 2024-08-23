import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/geojson.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class ReportMap extends StatefulWidget {
  const ReportMap({super.key});

  @override
  State<ReportMap> createState() => _ReportMapState();
}

class _ReportMapState extends State<ReportMap> {
  final mapController = Completer<MapLibreMapController>();
  final _scrollController = ScrollController();
  List<PartialEarthquakeReport> reportList = [];
  DateTime? lastFetchTime;
  int page = 1;
  bool isLoading = false;
  int _currentPage = 1;
  int _loadedPage = 0;

  Future<void> refreshReportList() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!).inMinutes < 1) {
      return;
    }

    var newList = await ExpTech().getReportList(limit: 500);
    addToList(newList);
  }

  void _loadMore() {
    if (isLoading) return;
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        _currentPage++;
        _fetchNextPage();
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (isLoading) return;
    if (_currentPage <= _loadedPage) {
      setState(() {
        _currentPage = _loadedPage;
      });
      return;
    }

    setState(() => isLoading = true);

    var newList = await ExpTech().getReportList(limit: 500, page: _currentPage);
    addToList(newList);

    setState(() {
      _loadedPage = _currentPage;
      isLoading = false;
    });
  }

  Future updateMapData() async {
    final map = await mapController.future;
    final geojson = GeoJsonBuilder();

    for (final report in reportList.sublist(0, 50)) {
      geojson.addFeature(
        GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
            .setGeometry(report.latlng.toGeoJsonCoordinates())
            .setProperty("magnitude", report.magnitude),
      );
    }

    await map.setGeoJsonSource("report", geojson.build());
  }

  void addToList(List<PartialEarthquakeReport> list) {
    final oldIdList = reportList.map((v) => v.id);

    list.removeWhere(
      (r) => oldIdList.contains(r.id),
    );

    list = reportList + list;

    list.sort((a, b) => b.time.difference(a.time).inMilliseconds);

    setState(() {
      reportList = list;
      lastFetchTime = DateTime.now();
    });

    updateMapData();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    _fetchNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(
          onMapCreated: (controller) async {
            await loadCrossImage(controller);
            await controller.addGeoJsonSource("report", GeoJsonBuilder().build());
            await controller.addSymbolLayer(
              "report",
              "report-cross",
              const SymbolLayerProperties(
                iconImage: "cross",
                iconSize: [
                  Expressions.multiply,
                  [Expressions.get, "magnitude"],
                ],
              ),
            );
            mapController.complete(controller);
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            builder: (context, scrollController) {
              return Container();
            },
          ),
        ),
      ],
    );
  }
}
