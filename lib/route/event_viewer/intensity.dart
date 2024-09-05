import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/util/need_location.dart';
import 'package:dpip/util/parser.dart';
import 'package:dpip/util/radar_color.dart';
import 'package:dpip/widget/chip/label_chip.dart';
import 'package:dpip/widget/list/detail_field_tile.dart';
import 'package:dpip/widget/map/legend.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';

class IntensityPage extends StatefulWidget {
  final History item;

  const IntensityPage({super.key, required this.item});

  @override
  _IntensityPageState createState() => _IntensityPageState();
}

class _IntensityPageState extends State<IntensityPage> {
  late MapLibreMapController _mapController;
  List<String> radarList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  Timer? _update;
  History? data;

  @override
  void initState() {
    super.initState();
    data = widget.item;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _update?.cancel();
    super.dispose();
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  void _initMap(MapLibreMapController controller) {
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

    radarList = await ExpTech().getRadarList();

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

    isUserLocationValid = (userLon != 0 && userLat != 0);

    if (isUserLocationValid) {
      await _mapController.setGeoJsonSource(
        "markers-geojson",
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {},
              "geometry": {
                "coordinates": [userLon, userLat],
                "type": "Point"
              }
            }
          ],
        },
      );
      final cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(userLat, userLon), 8);
      await _mapController.animateCamera(cameraUpdate, duration: const Duration(milliseconds: 1000));
    }

    if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
      await showLocationDialog(context);
    }

    await _addUserLocationMarker();

    setState(() {});

    getEventInfo();

    if (widget.item.addition?["final"] != 1) {
      _update = Timer.periodic(const Duration(seconds: 1), (_) async {
        data = (await ExpTech().getEvent(widget.item.id))[0];
        getEventInfo();
        if (data?.addition?["final"] == 1) {
          _update?.cancel();
        }
      });
    }
  }

  void getEventInfo() async {
    Map<String, dynamic> originalArea = data?.addition?['area'];
    Map<String, int> invertedArea = {};

    originalArea.forEach((key, value) {
      for (var code in value) {
        invertedArea[code.toString()] = int.parse(key);
      }
    });
    _mapController.setLayerProperties(
      "town",
      FillLayerProperties(
        fillColor: [
          "match",
          ["get", "CODE"],
          ...invertedArea.entries.expand((entry) => [
                int.parse(entry.key),
                IntensityColor.intensity(entry.value).toHexStringRGB(),
              ]),
          context.colors.surfaceContainerHighest.toHexStringRGB(),
        ],
        fillOpacity: 1,
      ),
    );
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
    return SizedBox(
      height: 20,
      width: 300,
      child: CustomPaint(
        painter: ColorBarPainter(dBZColors),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = List.generate(14, (index) => (index * 5).toString());
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map((label) => Text(
                  label,
                  style: const TextStyle(fontSize: 9),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.text.content['all']?.title ?? ""),
        elevation: 0,
      ),
      body: Stack(
        children: [
          DpipMap(
            onMapCreated: _initMap,
            onStyleLoadedCallback: _loadMap,
            rotateGesturesEnabled: true,
          ),
          Positioned(
            right: 4,
            top: 4,
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
          if (_showLegend)
            Positioned(
              right: 6,
              top: 50, // Adjusted to be above the legend button
              child: _buildLegend(),
            ),
          _buildDraggableSheet(context),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      snap: true,
      snapSizes: const [0.15, 0.35, 1],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: kElevationToShadow[4],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const BottomSheetDragHandle(),
              _buildWarningHeader(),
              const Divider(),
              _buildWarningDetails(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 0, 0),
                child: Text("僅供參考實際應以中央氣象署發布之內容為準", style: TextStyle(color: context.colors.error)),
              ),
              const SizedBox(height: 20),
              _buildAffectedAreas(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarningHeader() {
    final String subtitle = widget.item.text.content["all"]?.subtitle ?? "";

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ListIcons.getListIcon(widget.item.icon), size: 28),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Text(
                subtitle,
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              LabelChip(
                label:
                    "第${data?.addition?["serial"]}報${(data?.addition?["final"] == 1) ? context.i18n.history_final : ""}",
                backgroundColor: context.colors.secondaryContainer,
                foregroundColor: context.colors.onSecondaryContainer,
                outlineColor: context.colors.secondaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningDetails() {
    final DateTime sendTime = widget.item.time.send;
    final int expireTimestamp = widget.item.time.expires['all']!;
    final TZDateTime expireTimeUTC = parseDateTime(expireTimestamp);
    final String description = data?.text.description["all"] ?? "";
    final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
    final DateTime localExpireTime = expireTimeUTC;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            description,
            style: context.theme.textTheme.bodyLarge,
          ),
        ),
        _buildTimeBar(context, sendTime, localExpireTime, isExpired),
      ],
    );
  }

  Widget _buildTimeBar(BuildContext context, DateTime sendTime, DateTime expireTime, bool isExpired) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeInfo(context, Symbols.schedule_rounded, context.i18n.history_send_time, sendTime),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, IconData icon, String label, DateTime time) {
    return Row(
      children: [
        Icon(icon, color: context.colors.secondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.theme.textTheme.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(time),
              style: context.theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAffectedAreas() {
    final grouped = groupBy(data!.area.map((e) => Global.location[e.toString()]!), (e) => e.city);
    List<Widget> areas = [];

    for (final MapEntry(key: city, value: locations) in grouped.entries) {
      areas.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      city,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: locations.map((e) {
                        return Chip(
                          padding: const EdgeInsets.all(4),
                          side: BorderSide(color: context.colors.outline),
                          backgroundColor: context.colors.surfaceContainerHigh,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          label: Text(e.town),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return DetailFieldTile(
      label: context.i18n.history_affected_area,
      child: Column(children: areas),
    );
  }
}
