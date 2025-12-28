import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/route.dart';
import 'package:dpip/app/map/_widgets/map_legend.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/list_icon.dart';
import 'package:dpip/utils/serialization.dart';
import 'package:dpip/widgets/chip/label_chip.dart';
import 'package:dpip/widgets/list/detail_field_tile.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/bottom_sheet_drag_handle.dart';

class ThunderstormPage extends StatefulWidget {
  final History item;

  const ThunderstormPage({super.key, required this.item});

  @override
  _ThunderstormPageState createState() => _ThunderstormPageState();
}

class _ThunderstormPageState extends State<ThunderstormPage> {
  late MapLibreMapController _mapController;
  List<String> radarList = [];
  double? userLat;
  double? userLon;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  Timer? _blinkTimer;
  int _blink = 0;
  bool isExpired = true;

  @override
  void dispose() {
    _mapController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    final outlineColor = context.colors.outline.toHexStringRGB();

    final list = await ExpTech().getRadarList();

    if (mounted) {
      setState(() {
        radarList = list;
      });
    }
    final String newTileUrl = Routes.radarTile(radarList.last);

    await _mapController.addSource(
      'radarSource',
      RasterSourceProperties(tiles: [newTileUrl], tileSize: 256),
    );

    if (!isExpired) {
      await _mapController.addLayer(
        'radarSource',
        'radarLayer',
        const RasterLayerProperties(),
        belowLayerId: BaseMapLayerIds.userLocation,
      );
    }

    await _mapController.addLayer(
      'exptech',
      'town-outline-default',
      LineLayerProperties(lineColor: outlineColor, lineWidth: 1),
      sourceLayer: 'town',
      belowLayerId: BaseMapLayerIds.userLocation,
    );

    await _mapController.addLayer(
      'exptech',
      'town-outline-highlighted',
      const LineLayerProperties(lineColor: '#9e10fd', lineWidth: 2),
      sourceLayer: 'town',
      filter: [
        'in',
        ['get', 'CODE'],
        ['literal', widget.item.area],
      ],
      belowLayerId: BaseMapLayerIds.userLocation,
    );

    if (GlobalProviders.location.auto) {
      await updateLocationFromGPS();
    }

    await _mapController.addSource(
      'markers-geojson',
      const GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    start();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!mounted) return;
      await _mapController.setLayerProperties(
        'town-outline-highlighted',
        LineLayerProperties(lineOpacity: (_blink < 6) ? 1 : 0),
      );
      _blink++;
      if (_blink >= 8) _blink = 0;
    });
  }

  Future<void> start() async {
    final location = GlobalProviders.location.coordinates;

    if (location != null && location.isValid) {
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(location, 7.4),
      );
    } else {
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4),
      );
    }
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return ColorLegend(
      reverse: true,
      unit: 'dBZ',
      items: [
        ColorLegendItem(color: const Color(0xff00ffff), value: 0),
        ColorLegendItem(color: const Color(0xff00a3ff), value: 5),
        ColorLegendItem(color: const Color(0xff005bff), value: 10),
        ColorLegendItem(
          color: const Color(0xff0000ff),
          value: 15,
          blendTail: false,
        ),
        ColorLegendItem(
          color: const Color(0xff00ff00),
          value: 16,
          hidden: true,
        ),
        ColorLegendItem(color: const Color(0xff00d300), value: 20),
        ColorLegendItem(color: const Color(0xff00a000), value: 25),
        ColorLegendItem(color: const Color(0xffccea00), value: 30),
        ColorLegendItem(color: const Color(0xffffd300), value: 35),
        ColorLegendItem(color: const Color(0xffff8800), value: 40),
        ColorLegendItem(color: const Color(0xffff1800), value: 45),
        ColorLegendItem(color: const Color(0xffd30000), value: 50),
        ColorLegendItem(color: const Color(0xffa00000), value: 55),
        ColorLegendItem(color: const Color(0xffea00cc), value: 60),
        ColorLegendItem(color: const Color(0xff9600ff), value: 65),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TZDateTime radarDateTime = TZDateTime.fromMillisecondsSinceEpoch(
      UTC,
      radarList.isEmpty ? 0 : int.parse(radarList.last),
    );
    final TZDateTime radarTime = TZDateTime.from(
      radarDateTime,
      getLocation('Asia/Taipei'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.text.content['all']?.title ?? ''),
        elevation: 0,
      ),
      body: Stack(
        children: [
          DpipMap(onMapCreated: _initMap, onStyleLoadedCallback: _loadMap),
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
                  message: '雷達合成回波',
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
          Positioned(
            left: 4,
            top: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.5),
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
            top: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    '雷達合成回波',
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
            padding: EdgeInsets.fromLTRB(16, 0, 16, context.padding.bottom),
            children: [
              const BottomSheetDragHandle(),
              _buildWarningHeader(),
              const Divider(),
              _buildWarningDetails(),
              const SizedBox(height: 20),
              _buildAffectedAreas(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarningHeader() {
    final String subtitle = widget.item.text.content['all']?.subtitle ?? '';
    final int expireTimestamp = widget.item.time.expires['all']!;
    final TZDateTime expireTimeUTC = parseDateTime(expireTimestamp);
    isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());

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
            child: Icon(getListIcon(widget.item.icon), size: 28),
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
              if (isExpired)
                LabelChip(
                  label: '已結束',
                  backgroundColor: context.colors.surfaceContainer,
                  foregroundColor: context.colors.onSurfaceVariant,
                )
              else
                LabelChip(
                  label: '生效中',
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
    final String description = widget.item.text.description['all'] ?? '';
    final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
    final DateTime localExpireTime = expireTimeUTC;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(description, style: context.theme.textTheme.bodyLarge),
        ),
        _buildTimeBar(context, sendTime, localExpireTime, isExpired),
      ],
    );
  }

  Widget _buildTimeBar(
    BuildContext context,
    DateTime sendTime,
    DateTime expireTime,
    bool isExpired,
  ) {
    final Duration duration = expireTime.difference(sendTime);
    final Duration elapsed = isExpired
        ? duration
        : DateTime.now().difference(sendTime);
    final double progress = elapsed.inSeconds / duration.inSeconds;

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
          _buildTimeInfo(context, Symbols.schedule_rounded, '發送時間', sendTime),
          const SizedBox(height: 12),
          _buildTimeInfo(context, Symbols.flag_rounded, '有效至', expireTime),
          const SizedBox(height: 16),
          Stack(
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                borderRadius: BorderRadius.circular(8),
                color: isExpired
                    ? context.colors.outline
                    : context.colors.primary,
                backgroundColor: context.colors.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MM/dd HH:mm').format(sendTime),
                style: context.theme.textTheme.labelMedium,
              ),
              Text(
                DateFormat('MM/dd HH:mm').format(expireTime),
                style: context.theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    IconData icon,
    String label,
    DateTime time,
  ) {
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
    final grouped = groupBy(
      widget.item.area.map((e) => Global.location[e.toString()]!),
      (e) => e.cityWithLevel,
    );
    final List<Widget> areas = [];

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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(e.townWithLevel),
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
      label: '影響區域',
      child: Column(children: areas),
    );
  }
}
