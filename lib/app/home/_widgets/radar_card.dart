import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/radar/page.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';

typedef PositionUpdateCallback = void Function();

class RadarMapCard extends StatefulWidget {
  const RadarMapCard({super.key});

  @override
  State<RadarMapCard> createState() => _RadarMapCardState();
}

class _RadarMapCardState extends State<RadarMapCard> {
  late MapLibreMapController mapController;
  List<String> radarList = [];

  String _getTileUrl(String timestamp) {
    return 'https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png';
  }

  Future<void> _initializeMap() async {
    try {
      radarList = await ExpTech().getRadarList();
      if (!mounted) return;

      await _setupRadarLayer();
      if (!mounted) return;
    } catch (e) {
      TalkerManager.instance.error('RadarMapCard._initializeMap', e);
    }
  }

  Future<void> _setupRadarLayer() async {
    try {
      final newTileUrl = _getTileUrl(radarList.last);

      await mapController.addSource('radar-source', RasterSourceProperties(tiles: [newTileUrl], tileSize: 256));
      if (!mounted) return;

      await mapController.addLayer(
        'radar-source',
        'radar',
        const RasterLayerProperties(),
        belowLayerId: 'county-outline',
      );
    } catch (e) {
      TalkerManager.instance.error('RadarMapCard._setupRadarLayer', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              border: Border.all(color: context.colors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    child: Selector<SettingsUserInterfaceModel, ({ThemeMode? themeMode, Color? themeColor})>(
                      selector: (context, ui) => (themeMode: ui.themeMode, themeColor: ui.themeColor),
                      builder: (context, data, _) {
                        final (:themeMode, :themeColor) = data;

                        return DpipMap(
                          key: Key('$themeMode-$themeColor'),
                          onMapCreated: (controller) => mapController = controller,
                          onStyleLoadedCallback: () => _initializeMap(),
                          dragEnabled: false,
                          rotateGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            const Icon(Symbols.radar, size: 24),
                            Text(context.i18n.radar_monitor, style: context.textTheme.titleMedium),
                            if (radarList.isNotEmpty)
                              Text(
                                radarList.last.toLocaleTimeString(context),
                                style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const Icon(Symbols.chevron_right_rounded, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => context.push(MapRadarPage.route), borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
