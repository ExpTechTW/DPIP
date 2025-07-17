import 'package:dpip/widgets/layout.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/map.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/widgets/map/map.dart';

class SettingsMapPage extends StatelessWidget {
  const SettingsMapPage({super.key});

  static const route = '/settings/map';

  Future<void> showLayerSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: context.bottomSheetConstraints,
      builder: (context) {
        return LayerToggleSheet(
          activeLayers: context.read<SettingsMapModel>().layers,
          currentBaseMap: context.read<SettingsMapModel>().baseMap,
          onLayerChanged: (layer, show, activeLayers) {
            context.read<SettingsMapModel>().setLayers(activeLayers);
          },
          onBaseMapChanged: (baseMap) {
            context.read<SettingsMapModel>().setBaseMapType(baseMap);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final layerLabels = {
      MapLayer.monitor: '監視器'.i18n,
      MapLayer.report: '地震報告'.i18n,
      MapLayer.tsunami: '海嘯資訊'.i18n,
      MapLayer.radar: '雷達回波'.i18n,
      MapLayer.temperature: '氣溫'.i18n,
      MapLayer.precipitation: '降水'.i18n,
      MapLayer.wind: '風向/風速'.i18n,
    };
    final baseMapLabels = {
      BaseMapType.exptech: '線條'.i18n,
      BaseMapType.osm: 'OpenStreetMap'.i18n,
      BaseMapType.google: 'Google'.i18n,
    };

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '地圖'.i18n,
          children: [
            Selector<SettingsMapModel, BaseMapType>(
              selector: (context, model) => model.baseMap,
              builder: (context, baseMapType, child) {
                return ListSectionTile(
                  icon: Symbols.layers_rounded,
                  title: '底圖'.i18n,
                  subtitle: Text(baseMapLabels[baseMapType]!),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  onTap: () => showLayerSheet(context),
                );
              },
            ),
            Selector<SettingsMapModel, Set<MapLayer>>(
              selector: (context, model) => model.layers,
              builder: (context, layers, child) {
                return ListSectionTile(
                  icon: Symbols.layers_rounded,
                  title: '初始圖層'.i18n,
                  subtitle: Text(layers.map((e) => layerLabels[e]!).join(', ')),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  onTap: () => showLayerSheet(context),
                );
              },
            ),
            Selector<SettingsMapModel, int>(
              selector: (context, model) => model.updateInterval,
              builder: (context, updateInterval, child) {
                final maxFpsAllowed =
                    WidgetsBinding.instance.platformDispatcher.views.first.display.refreshRate.floorToDouble();

                return Layout.v.left[8](
                  padding: const EdgeInsets.all(16),
                  children: [
                    Layout.h.left[16](
                      children: [
                        Icon(Symbols.animation_rounded, weight: 600, color: context.colors.secondary),
                        Layout.v.left(
                          children: [
                            Text(
                              '動畫幀率'.i18n,
                              style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '影響強震監視器的震波模擬動畫流暢度'.i18n,
                              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Layout.h.left[4](
                      children: [
                        Expanded(
                          child: Slider(
                            value: updateInterval.toDouble().clamp(1, maxFpsAllowed),
                            min: 1,
                            max: maxFpsAllowed,
                            divisions: maxFpsAllowed.floor() ~/ 5,
                            onChanged: (value) {
                              context.read<SettingsMapModel>().setUpdateInterval(value.floor());
                            },
                            year2023: false,
                          ),
                        ),
                        SizedBox(width: 28, child: Text('$updateInterval', style: context.textTheme.labelSmall)),
                      ],
                    ),
                    if (updateInterval > 20)
                      Layout.h.left[8](
                        children: [
                          Icon(Symbols.warning_rounded, color: context.theme.extendedColors.amber, size: 16),
                          Expanded(
                            child: Text(
                              '過高的動畫幀率可能會造成卡頓或設備發熱'.i18n,
                              style: context.textTheme.bodySmall?.copyWith(color: context.theme.extendedColors.amber),
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
