import 'dart:async';
import 'dart:io';
import "dart:ui" as ui;

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/list_icon.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/util/need_location.dart';
import 'package:dpip/util/radar_color.dart';
import 'package:dpip/widget/map/legend.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:timezone/timezone.dart';

class ThunderstormPage extends StatefulWidget {
  final History item;

  const ThunderstormPage({super.key, required this.item});

  @override
  _ThunderstormPageState createState() => _ThunderstormPageState();
}

class _ThunderstormPageState extends State<ThunderstormPage> {
  late MapLibreMapController _mapController;
  List<String> radarList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  Timer? _blinkTimer;
  int _blink = 0;

  @override
  void dispose() {
    _mapController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  String getTileUrl(String timestamp) {
    return "https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png";
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

    String newTileUrl = getTileUrl(radarList.last);

    await _mapController.addSource(
      "radarSource",
      RasterSourceProperties(
        tiles: [newTileUrl],
        tileSize: 256,
      ),
    );

    _mapController.removeLayer("county");
    await _mapController.addLayer(
      "map",
      "county",
      FillLayerProperties(
        fillColor: context.colors.surfaceContainerHigh.toHexStringRGB(),
        fillOpacity: 1,
      ),
      sourceLayer: "city",
      belowLayerId: "radarLayer",
    );

    await _mapController.addLayer(
      "map",
      "town-outline-default",
      LineLayerProperties(
        lineColor: context.colors.outline.toHexStringRGB(),
        lineWidth: 1,
      ),
      sourceLayer: "town",
    );

    await _mapController.addLayer(
      "map",
      "town-outline-highlighted",
      const LineLayerProperties(
        lineColor: "#9e10fd",
        lineWidth: 6,
      ),
      sourceLayer: "town",
      filter: [
        'in',
        ['get', 'CODE'],
        ['literal', widget.item.area]
      ],
    );

    await _mapController.addLayer(
      "radarSource",
      "radarLayer",
      const RasterLayerProperties(),
      belowLayerId: "county-outline",
    );

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }

    await _mapController.addSource(
      "markers-geojson",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );

    start();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted) return;
      await _mapController.setLayerProperties(
          "town-outline-highlighted", LineLayerProperties(lineOpacity: (_blink < 6) ? 1 : 0));
      _blink++;
      if (_blink >= 8) _blink = 0;
    });
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
    final TZDateTime radarDateTime =
        TZDateTime.fromMillisecondsSinceEpoch(UTC, radarList.isEmpty ? 0 : int.parse(radarList.last));
    final TZDateTime radarTime = TZDateTime.from(radarDateTime, getLocation('Asia/Taipei'));

    return Scaffold(
      extendBodyBehindAppBar: true,
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
            top: 104,
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
              top: 150, // Adjusted to be above the legend button
              child: _buildLegend(),
            ),
          Positioned(
            left: 4,
            top: 104,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(radarTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 132,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withOpacity(0.5),
                  ),
                  child: Text(
                    "雷達合成回波",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildDraggableSheet(context),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      snap: true,
      snapSizes: const [0.1, 0.3, 0.9],
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.onPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 15),
                  _buildWarningHeader(context),
                  const SizedBox(height: 15),
                  _buildWarningDetails(context),
                  const SizedBox(height: 20),
                  _buildAffectedAreas(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildWarningHeader(BuildContext context) {
    final String subtitle = widget.item.text.content["all"]?.subtitle ?? "";
    final int expireTimestamp = widget.item.time.expires['all'];
    final TZDateTime expireTimeUTC = _convertToTZDateTime(expireTimestamp);
    final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(ListIcons.getListIcon(widget.item.icon), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isExpired)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "已結束",
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!isExpired)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "生效中",
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningDetails(BuildContext context) {
    final DateTime sendTime = widget.item.time.send;
    final int expireTimestamp = widget.item.time.expires['all'];
    final TZDateTime expireTimeUTC = _convertToTZDateTime(expireTimestamp);
    final String description = widget.item.text.description["all"] ?? "";
    final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
    final DateTime localExpireTime = expireTimeUTC;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeBar(context, sendTime, localExpireTime, isExpired),
        const SizedBox(height: 15),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              description,
              style: context.theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  TZDateTime _convertToTZDateTime(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    TZDateTime taipeTime = TZDateTime.from(dateTime, getLocation('Asia/Taipei'));
    return taipeTime;
  }

  Widget _buildTimeBar(BuildContext context, DateTime sendTime, DateTime expireTime, bool isExpired) {
    final Duration duration = expireTime.difference(sendTime);
    final Duration elapsed = isExpired ? duration : DateTime.now().difference(sendTime);
    final double progress = elapsed.inSeconds / duration.inSeconds;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeInfo(context, Icons.access_time, context.i18n.history_send_time, sendTime),
            const SizedBox(height: 12),
            _buildTimeInfo(context, Icons.timer_off, context.i18n.history_valid_until, expireTime),
            const SizedBox(height: 16),
            Stack(
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: context.colors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(isExpired ? context.colors.error : context.colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd HH:mm').format(sendTime), style: context.theme.textTheme.bodySmall),
                Text(DateFormat('MM/dd HH:mm').format(expireTime), style: context.theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, IconData icon, String label, DateTime time) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.secondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(time),
              style: context.theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAffectedAreas(BuildContext context) {
    final List<int> areaCodes = List<int>.from(widget.item.area);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.history_influence_area,
          style: context.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: areaCodes.map((code) => _buildAreaChip(context, code)).toList(),
        ),
      ],
    );
  }

  Widget _buildAreaChip(BuildContext context, int code) {
    final location = Global.location[code.toString()];
    final city = location?.city ?? '';
    final town = location?.town ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      child: Material(
        elevation: 2,
        shadowColor: context.colors.shadow,
        borderRadius: BorderRadius.circular(20),
        color: context.colors.surfaceVariant,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  "$city$town",
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
