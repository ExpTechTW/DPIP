import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';

class LayerToggleSheet extends StatefulWidget {
  final MapLayer? currentLayer;
  final void Function(MapLayer? layer) onChanged;

  const LayerToggleSheet({super.key, required this.currentLayer, required this.onChanged});

  @override
  State<LayerToggleSheet> createState() => _LayerToggleSheetState();
}

class _LayerToggleSheetState extends State<LayerToggleSheet> {
  late MapLayer? _currentLayer = widget.currentLayer;

  void _changeLayer(MapLayer? layer) {
    setState(() => _currentLayer = layer);
    widget.onChanged(layer);
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      icon: Symbols.layers_rounded,
      title: '地圖圖層',
      description: '選擇要顯示的地圖圖層',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const LabeledDivider(label: '地震'),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: context.i18n.monitor,
                checked: _currentLayer == MapLayer.monitor,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.monitor : null),
              ),
              LayerToggle(
                label: context.i18n.report,
                checked: _currentLayer == MapLayer.report,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.report : null),
              ),
              LayerToggle(
                label: context.i18n.tsunami_info_monitor,
                checked: _currentLayer == MapLayer.tsunami,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.tsunami : null),
              ),
            ],
          ),
          const LabeledDivider(label: '氣象'),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: context.i18n.radar_monitor,
                checked: _currentLayer == MapLayer.radar,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.radar : null),
              ),
              LayerToggle(
                label: context.i18n.temperature_monitor,
                checked: _currentLayer == MapLayer.temperature,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.temperature : null),
              ),
              LayerToggle(
                label: context.i18n.precipitation_monitor,
                checked: _currentLayer == MapLayer.precipitation,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.precipitation : null),
              ),
              LayerToggle(
                label: context.i18n.wind_direction_and_speed_monitor,
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
