import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/map.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsMapPage extends StatelessWidget {
  const SettingsMapPage({super.key});

  Future<void> showLayerSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: context.bottomSheetConstraints,
      builder: (context) {
        return LayerToggleSheet(
          activeLayers: context.map.layers,
          currentBaseMap: context.map.baseMap,
          onLayerChanged: (layer, show, activeLayers) {
            context.map.setLayers(activeLayers);
          },
          onBaseMapChanged: (baseMap) {
            context.map.setBaseMapType(baseMap);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.only(
      top: 16,
      bottom: 16 + context.padding.bottom,
    ),
    children: [
      SettingsHeader(
        icon: Symbols.map_rounded,
        title: Text('地圖'.i18n),
        subtitle: Text('調整地圖的顯示樣式'.i18n),
      ),
      const SizedBox(height: 16),
      SegmentedList(
        children: [
          SegmentedListTile(
            isFirst: true,
            leading: ContainedIcon(
              Symbols.layers_rounded,
              color: Colors.tealAccent,
            ),
            title: Text('初始圖層'.i18n),
            subtitle: Text('調整地圖的底圖以及初始顯示的圖層'.i18n),
            trailing: Icon(Symbols.chevron_right_rounded),
            onTap: () => showLayerSheet(context),
          ),
          Selector<SettingsMapModel, bool>(
            selector: (_, model) => model.autoZoom,
            builder: (context, autoZoom, child) {
              return SegmentedListTile(
                leading: ContainedIcon(
                  Symbols.zoom_in_rounded,
                  color: Colors.blueAccent,
                ),
                title: Text('自動縮放'.i18n),
                subtitle: Text('接收到檢知時自動縮放地圖'.i18n),
                trailing: Switch(
                  value: autoZoom,
                  onChanged: (value) => context.map.setAutoZoom(value),
                ),
              );
            },
          ),
          Selector<SettingsMapModel, int>(
            selector: (_, model) => model.updateInterval,
            builder: (context, updateInterval, child) {
              final maxFpsAllowed = WidgetsBinding
                  .instance
                  .platformDispatcher
                  .views
                  .first
                  .display
                  .refreshRate
                  .floorToDouble();

              return SegmentedListTile(
                isLast: true,
                leading: ContainedIcon(
                  Symbols.animation_rounded,
                  color: Colors.orangeAccent,
                ),
                title: Text('動畫幀率'.i18n),
                subtitle: Text('調整強震監視器震波模擬動畫的流暢度'.i18n),
                content: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        LabelText.small('1'),
                        Expanded(
                          child: Slider(
                            value: updateInterval.toDouble().clamp(
                              1,
                              maxFpsAllowed,
                            ),
                            min: 1,
                            max: maxFpsAllowed,
                            divisions: maxFpsAllowed.floor() ~/ 5,
                            label: '$updateInterval FPS',
                            onChanged: (value) =>
                                context.map.setUpdateInterval(value.floor()),
                          ),
                        ),
                        LabelText.small('${maxFpsAllowed.floor()}'),
                      ],
                    ),
                    if (updateInterval > 20)
                      Layout.row.left[8](
                        children: [
                          Icon(
                            Symbols.warning_rounded,
                            color: context.theme.extendedColors.amber,
                            size: 16,
                          ),
                          Expanded(
                            child: BodyText.small(
                              '過高的動畫幀率可能會造成卡頓或裝置發熱'.i18n,
                              color: context.theme.extendedColors.amber,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
