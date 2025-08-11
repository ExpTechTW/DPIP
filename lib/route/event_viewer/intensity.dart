import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/intensity_history.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:dpip/utils/list_icon.dart';
import 'package:dpip/utils/parser.dart';
import 'package:dpip/widgets/chip/label_chip.dart';
import 'package:dpip/widgets/list/detail_field_tile.dart';
import 'package:dpip/widgets/map/legend.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/bottom_sheet_drag_handle.dart';

class IntensityPage extends StatefulWidget {
  final IntensityHistory item;

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
  late IntensityHistory data = widget.item;

  @override
  void dispose() {
    _mapController.dispose();
    _update?.cancel();
    super.dispose();
  }

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    radarList = await ExpTech().getRadarList();

    if (Platform.isIOS && GlobalProviders.location.auto) {
      await updateSavedLocationIOS();
    }

    await _mapController.addSource(
      'markers-geojson',
      const GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': []}),
    );

    start();
  }

  Future<void> start() async {
    final location = GlobalProviders.location.coordinates;

    if (location != null && location.isValid) {
      await _mapController.animateCamera(CameraUpdate.newLatLngZoom(location, 7.4));
    } else {
      await _mapController.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
    }

    getEventInfo();

    if (!widget.item.addition.isFinal) {
      _update = Timer.periodic(const Duration(seconds: 1), (_) async {
        data = (await ExpTech().getEvent(widget.item.id))[0] as IntensityHistory;
        getEventInfo();
        if (data.addition.isFinal == true) {
          _update?.cancel();
        }
      });
    }
  }

  Future<void> getEventInfo() async {
    final originalArea = data.addition.area;
    final Map<String, int> invertedArea = {};

    originalArea.forEach((key, value) {
      for (final code in value) {
        invertedArea[code.toString()] = int.parse(key);
      }
    });

    await _mapController.setLayerProperties(
      'town',
      FillLayerProperties(
        fillColor: [
          'match',
          ['get', 'CODE'],
          ...invertedArea.entries.expand(
            (entry) => [int.parse(entry.key), IntensityColor.intensity(entry.value).toHexStringRGB()],
          ),
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
      label: 'TREM 觀測網實測震度',
      children: [
        _buildColorBar(),
        const SizedBox(height: 8),
        _buildColorBarLabels(),
        Text('使用 JMA 震度標準 (0.3秒三分量合成加速度)', style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildColorBar() {
    final intensities = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    return SizedBox(
      height: 20,
      width: 300,
      child: Row(
        children:
            intensities.map((intensity) {
              return Expanded(child: Container(color: IntensityColor.intensity(intensity)));
            }).toList(),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = List.generate(9, (i) {
      final count = i + 1;
      const map = {5: '5弱', 6: '5強', 7: '6弱', 8: '6強', 9: '7級'};
      return map[count] ?? '$count級';
    });

    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            labels.map((label) {
              return SizedBox(
                width: 300 / 9,
                child: Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.text.content['all']?.title ?? ''), elevation: 0),
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
                  message: '圖例',
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
                child: Text(
                  '本資料係由 TREM-Net 觀測網自動觀測結果所得，尚未經人為檢視確認，僅供應變之初步參考。實際應以中央氣象署發布之資訊為準。',
                  style: TextStyle(color: context.colors.error),
                ),
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
    final String subtitle = widget.item.text.content['all']?.subtitle ?? '';

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
              Text(subtitle, style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              LabelChip(
                label: "第${data.addition.serial}報${(data.addition.isFinal) ? '(最終)' : ""}",
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
    final String description = data.text.description['all'] ?? '';
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

  Widget _buildTimeBar(BuildContext context, DateTime sendTime, DateTime expireTime, bool isExpired) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildTimeInfo(context, Symbols.schedule_rounded, '發送時間', sendTime)],
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
            Text(label, style: context.theme.textTheme.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
            Text(DateFormat('yyyy/MM/dd HH:mm').format(time), style: context.theme.textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildAffectedAreas() {
    final grouped = groupBy(data.area.map((e) => Global.location[e.toString()]!), (e) => e.city);
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
                    child: Text(city, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          locations.map((e) {
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

    return DetailFieldTile(label: '影響區域', child: Column(children: areas));
  }
}
