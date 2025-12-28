import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/map.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/widgets/layout.dart';
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
      MapLayer.lightning: '閃電'.i18n,
    };
    final baseMapLabels = {
      BaseMapType.exptech: '簡單'.i18n,
      BaseMapType.osm: 'OpenStreetMap'.i18n,
      BaseMapType.google: 'Google'.i18n,
    };

    return Consumer<SettingsMapModel>(
      builder: (context, model, child) {
        return ListView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBaseMapCard(context, model, baseMapLabels),
            _buildLayersCard(context, model, layerLabels),
            _buildAutoZoomCard(context, model),
            _buildAnimationFpsCard(context, model),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.map_rounded,
              color: context.colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '地圖設定'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '自訂地圖的顯示方式'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseMapCard(
    BuildContext context,
    SettingsMapModel model,
    Map<BaseMapType, String> baseMapLabels,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showLayerSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.layers_rounded,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '底圖'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        baseMapLabels[model.baseMap]!,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayersCard(
    BuildContext context,
    SettingsMapModel model,
    Map<MapLayer, String> layerLabels,
  ) {
    final layersText = model.layers.map((e) => layerLabels[e]!).join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showLayerSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.stacks_rounded,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '初始圖層'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        layersText.isEmpty ? '無'.i18n : layersText,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoZoomCard(BuildContext context, SettingsMapModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => model.setAutoZoom(!model.autoZoom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: model.autoZoom
                        ? Colors.blue.withValues(alpha: 0.15)
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.zoom_in_map_rounded,
                    color: model.autoZoom
                        ? Colors.blue
                        : context.colors.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '自動縮放'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: model.autoZoom
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '接收到檢知時自動縮放地圖(監視器模式下)'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant
                              .withValues(alpha: model.autoZoom ? 1 : 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: model.autoZoom,
                  onChanged: (value) => model.setAutoZoom(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationFpsCard(BuildContext context, SettingsMapModel model) {
    final maxFpsAllowed = WidgetsBinding.instance.platformDispatcher.views.first
        .display
        .refreshRate
        .floorToDouble();
    final updateInterval = model.updateInterval;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.animation_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '動畫幀率'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '影響強震監視器的震波模擬動畫流暢度'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '1',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: updateInterval.toDouble().clamp(1, maxFpsAllowed),
                    min: 1,
                    max: maxFpsAllowed,
                    divisions: maxFpsAllowed.floor() ~/ 5,
                    label: '$updateInterval FPS',
                    onChanged: (value) {
                      model.setUpdateInterval(value.floor());
                    },
                  ),
                ),
                Text(
                  '${maxFpsAllowed.floor()}',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
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
                    child: Text(
                      '過高的動畫幀率可能會造成卡頓或設備發熱'.i18n,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.theme.extendedColors.amber,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
