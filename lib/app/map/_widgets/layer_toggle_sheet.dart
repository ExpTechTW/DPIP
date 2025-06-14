import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';

class LayerToggleSheet extends StatefulWidget {
  final MapLayer? currentLayer;
  final BaseMapType currentBaseMap;
  final void Function(MapLayer? layer) onChanged;
  final void Function(BaseMapType baseMap) onBaseMapChanged;

  const LayerToggleSheet({
    super.key,
    required this.currentLayer,
    required this.currentBaseMap,
    required this.onChanged,
    required this.onBaseMapChanged,
  });

  @override
  State<LayerToggleSheet> createState() => _LayerToggleSheetState();
}

class _LayerToggleSheetState extends State<LayerToggleSheet> {
  late MapLayer? _currentLayer = widget.currentLayer;
  late BaseMapType? _currentBaseMap = widget.currentBaseMap;

  void _changeLayer(MapLayer? layer) {
    setState(() => _currentLayer = layer);
    widget.onChanged(layer);
  }

  void _changeBaseMap(BaseMapType baseMap) {
    setState(() => _currentBaseMap = baseMap);
    widget.onBaseMapChanged(baseMap);
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      icon: Symbols.layers_rounded,
      title: '地圖圖層'.i18n,
      description: '選擇要顯示的地圖圖層'.i18n,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          LabeledDivider(label: '底圖'.i18n),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: '線條'.i18n,
                checked: _currentBaseMap == BaseMapType.exptech,
                onChanged: (checked) => _changeBaseMap(BaseMapType.exptech),
              ),
              LayerToggle(
                label: 'OpenStreetMap',
                checked: _currentBaseMap == BaseMapType.osm,
                onChanged: (checked) => _changeBaseMap(BaseMapType.osm),
              ),
              LayerToggle(
                label: 'Google',
                checked: _currentBaseMap == BaseMapType.google,
                onChanged: (checked) => _changeBaseMap(BaseMapType.google),
              ),
            ],
          ),
          LabeledDivider(label: '地震'.i18n),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: '強震監視器'.i18n,
                checked: _currentLayer == MapLayer.monitor,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.monitor : null),
              ),
              LayerToggle(
                label: '地震報告'.i18n,
                checked: _currentLayer == MapLayer.report,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.report : null),
              ),
              LayerToggle(
                label: '海嘯資訊'.i18n,
                checked: _currentLayer == MapLayer.tsunami,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.tsunami : null),
              ),
            ],
          ),
          LabeledDivider(label: '氣象'.i18n),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: '雷達回波'.i18n,
                checked: _currentLayer == MapLayer.radar,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.radar : null),
              ),
              LayerToggle(
                label: '氣溫'.i18n,
                checked: _currentLayer == MapLayer.temperature,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.temperature : null),
              ),
              LayerToggle(
                label: '降水'.i18n,
                checked: _currentLayer == MapLayer.precipitation,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.precipitation : null),
              ),
              LayerToggle(
                label: '風向/風速'.i18n,
                checked: _currentLayer == MapLayer.wind,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.wind : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
