import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class LayerToggleSheet extends StatefulWidget {
  final Set<MapLayer> activeLayers;
  final BaseMapType currentBaseMap;
  final void Function(MapLayer layer, bool state, Set<MapLayer> activeLayers)
  onLayerChanged;
  final void Function(BaseMapType baseMap) onBaseMapChanged;

  const LayerToggleSheet({
    super.key,
    required this.activeLayers,
    required this.currentBaseMap,
    required this.onLayerChanged,
    required this.onBaseMapChanged,
  });

  @override
  State<LayerToggleSheet> createState() => _LayerToggleSheetState();
}

class _LayerToggleSheetState extends State<LayerToggleSheet> {
  late Set<MapLayer> _activeLayers = Set.from(widget.activeLayers);
  late BaseMapType _currentBaseMap = widget.currentBaseMap;

  @override
  void didUpdateWidget(LayerToggleSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!setEquals(oldWidget.activeLayers, widget.activeLayers)) {
      setState(() => _activeLayers = widget.activeLayers);
    }

    if (oldWidget.currentBaseMap != widget.currentBaseMap) {
      setState(() => _currentBaseMap = widget.currentBaseMap);
    }
  }

  void _toggleLayer(MapLayer layer, {bool overlay = false}) {
    final Set<MapLayer> newLayers;

    if (overlay) {
      newLayers = Set.from(_activeLayers);
      final combination = kAllowedLayerCombinations[layer];
      if (combination != null) {
        newLayers.removeWhere((l) => !combination.contains(l));
      }
      newLayers.add(layer);
    } else {
      newLayers = {layer};
    }

    if (setEquals(_activeLayers, newLayers)) return;

    final oldLayers = _activeLayers;
    setState(() => _activeLayers = newLayers);

    for (final removedLayer in oldLayers.difference(newLayers)) {
      widget.onLayerChanged(removedLayer, false, newLayers);
    }

    for (final addedLayer in newLayers.difference(oldLayers)) {
      widget.onLayerChanged(addedLayer, true, newLayers);
    }
  }

  void _setBaseMap(BaseMapType baseMap) {
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
                label: '簡單'.i18n,
                checked: _currentBaseMap == BaseMapType.exptech,
                onChanged: (_) => _setBaseMap(BaseMapType.exptech),
              ),
              LayerToggle(
                label: 'OpenStreetMap',
                checked: _currentBaseMap == BaseMapType.osm,
                onChanged: (_) => _setBaseMap(BaseMapType.osm),
              ),
              LayerToggle(
                label: 'Google',
                checked: _currentBaseMap == BaseMapType.google,
                onChanged: (_) => _setBaseMap(BaseMapType.google),
              ),
            ],
          ),
          LabeledDivider(label: '地震'.i18n),
          Wrap(
            spacing: 4,
            runSpacing: 8,
            children: [
              LayerToggle(
                label: '監視器'.i18n,
                checked: _activeLayers.contains(MapLayer.monitor),
                onChanged: (_) => _toggleLayer(MapLayer.monitor),
              ),
              LayerToggle(
                label: '報告'.i18n,
                checked: _activeLayers.contains(MapLayer.report),
                onChanged: (_) => _toggleLayer(MapLayer.report),
              ),
              LayerToggle(
                label: '海嘯'.i18n,
                checked: _activeLayers.contains(MapLayer.tsunami),
                onChanged: null,
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
                checked: _activeLayers.contains(MapLayer.radar),
                onChanged: (_) => _toggleLayer(MapLayer.radar),
                onLongPress: (_) => _toggleLayer(MapLayer.radar, overlay: true),
              ),
              LayerToggle(
                label: '氣溫'.i18n,
                checked: _activeLayers.contains(MapLayer.temperature),
                onChanged: (_) => _toggleLayer(MapLayer.temperature),
                onLongPress: (_) =>
                    _toggleLayer(MapLayer.temperature, overlay: true),
              ),
              LayerToggle(
                label: '降水'.i18n,
                checked: _activeLayers.contains(MapLayer.precipitation),
                onChanged: (_) => _toggleLayer(MapLayer.precipitation),
                onLongPress: (_) =>
                    _toggleLayer(MapLayer.precipitation, overlay: true),
              ),
              LayerToggle(
                label: '風向/風速'.i18n,
                checked: _activeLayers.contains(MapLayer.wind),
                onChanged: (_) => _toggleLayer(MapLayer.wind),
                onLongPress: (_) => _toggleLayer(MapLayer.wind, overlay: true),
              ),
              LayerToggle(
                label: '閃電'.i18n,
                checked: _activeLayers.contains(MapLayer.lightning),
                onChanged: (_) => _toggleLayer(MapLayer.lightning),
                onLongPress: (_) =>
                    _toggleLayer(MapLayer.lightning, overlay: true),
              ),
              LayerToggle(
                label: '颱風'.i18n,
                checked: _activeLayers.contains(MapLayer.typhoon),
                onChanged: (checked) => _toggleLayer(MapLayer.typhoon),
                onLongPress: (_) => _toggleLayer(MapLayer.typhoon, overlay: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
