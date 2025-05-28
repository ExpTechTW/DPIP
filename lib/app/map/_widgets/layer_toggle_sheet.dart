import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';

class LayerToggleSheetHeader extends StatelessWidget {
  const LayerToggleSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const LabeledDivider(label: '氣象'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: 'Radar',
                checked: _currentLayer == MapLayer.radar,
                onChanged: (checked) => _changeLayer(checked ? MapLayer.radar : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
