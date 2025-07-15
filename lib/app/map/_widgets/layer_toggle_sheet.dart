import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class LayerToggleSheet extends StatefulWidget {
  final Set<MapLayer> activeLayers;
  final BaseMapType currentBaseMap;
  final void Function(MapLayer layer) onLayerToggled;
  final void Function(BaseMapType baseMap) onBaseMapChanged;

  const LayerToggleSheet({
    super.key,
    required this.activeLayers,
    required this.currentBaseMap,
    required this.onLayerToggled,
    required this.onBaseMapChanged,
  });

  @override
  State<LayerToggleSheet> createState() => _LayerToggleSheetState();
}

class _LayerToggleSheetState extends State<LayerToggleSheet> {
  late Set<MapLayer> _activeLayers = Set.from(widget.activeLayers);
  late BaseMapType _currentBaseMap = widget.currentBaseMap;

  static const Set<MapLayer> _earthquakeLayers = {MapLayer.monitor, MapLayer.report, MapLayer.tsunami};

  static const Set<MapLayer> _weatherLayers = {
    MapLayer.radar,
    MapLayer.temperature,
    MapLayer.precipitation,
    MapLayer.wind,
  };

  static const Map<MapLayer, Set<MapLayer>> _allowedRadarCombinations = {
    MapLayer.temperature: {MapLayer.radar, MapLayer.temperature},
    MapLayer.precipitation: {MapLayer.radar, MapLayer.precipitation},
    MapLayer.wind: {MapLayer.radar, MapLayer.wind},
  };

  @override
  void didUpdateWidget(LayerToggleSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeLayers != widget.activeLayers) {
      setState(() {
        _activeLayers = Set.from(widget.activeLayers);
      });
    }
    if (oldWidget.currentBaseMap != widget.currentBaseMap) {
      setState(() {
        _currentBaseMap = widget.currentBaseMap;
      });
    }
  }

  bool _isAllowedCombination(Set<MapLayer> layers) {
    final earthquakeCount = layers.where((l) => _earthquakeLayers.contains(l)).length;
    if (earthquakeCount > 1) return false;

    final weatherLayers = layers.where((l) => _weatherLayers.contains(l)).toSet();
    if (weatherLayers.isEmpty) return true;

    if (weatherLayers.length == 1) return true;

    if (weatherLayers.length == 2) {
      if (weatherLayers.contains(MapLayer.radar)) {
        final otherLayer = weatherLayers.where((l) => l != MapLayer.radar).first;
        return _allowedRadarCombinations.containsKey(otherLayer);
      }
    }

    return false;
  }

  void _toggleLayer(MapLayer layer, bool checked) {
    if (!checked && layer == MapLayer.monitor && _activeLayers.length == 1) {
      return;
    }

    widget.onLayerToggled(layer);
    setState(() {
      if (checked) {
        final newLayers = Set<MapLayer>.from(_activeLayers)..add(layer);

        if (_earthquakeLayers.contains(layer)) {
          _activeLayers.removeAll(_earthquakeLayers);
          _activeLayers.removeAll(_weatherLayers);
        } else if (_weatherLayers.contains(layer)) {
          final weatherLayersInNew = newLayers.where((l) => _weatherLayers.contains(l)).toSet();
          if (!_isAllowedCombination(weatherLayersInNew)) {
            if (weatherLayersInNew.contains(MapLayer.radar)) {
              final nonRadarWeatherLayers = _weatherLayers.where((l) => l != MapLayer.radar).toSet();
              _activeLayers.removeAll(nonRadarWeatherLayers);
            } else {
              _activeLayers.removeAll(_weatherLayers);
            }
          }
          _activeLayers.removeAll(_earthquakeLayers);
        }
        _activeLayers.add(layer);
      } else {
        _activeLayers.remove(layer);

        if (_weatherLayers.contains(layer)) {
          final hasOtherWeatherLayers = _activeLayers.any((l) => _weatherLayers.contains(l));
          if (!hasOtherWeatherLayers) {
            _activeLayers.add(MapLayer.monitor);
          }
        } else if (_earthquakeLayers.contains(layer) && layer != MapLayer.monitor) {
          _activeLayers.add(MapLayer.monitor);
        }
      }
    });
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
                checked: _activeLayers.contains(MapLayer.monitor),
                onChanged: (checked) => _toggleLayer(MapLayer.monitor, checked),
              ),
              LayerToggle(
                label: '地震報告'.i18n,
                checked: _activeLayers.contains(MapLayer.report),
                onChanged: (checked) => _toggleLayer(MapLayer.report, checked),
              ),
              LayerToggle(
                label: '海嘯資訊'.i18n,
                checked: _activeLayers.contains(MapLayer.tsunami),
                onChanged: null, //(checked) => _toggleLayer(MapLayer.tsunami, checked),
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
                onChanged: (checked) => _toggleLayer(MapLayer.radar, checked),
              ),
              LayerToggle(
                label: '氣溫'.i18n,
                checked: _activeLayers.contains(MapLayer.temperature),
                onChanged: (checked) => _toggleLayer(MapLayer.temperature, checked),
              ),
              LayerToggle(
                label: '降水'.i18n,
                checked: _activeLayers.contains(MapLayer.precipitation),
                onChanged: (checked) => _toggleLayer(MapLayer.precipitation, checked),
              ),
              LayerToggle(
                label: '風向/風速'.i18n,
                checked: _activeLayers.contains(MapLayer.wind),
                onChanged: (checked) => _toggleLayer(MapLayer.wind, checked),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
