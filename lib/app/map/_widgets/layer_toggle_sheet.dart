import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/sheet_container.dart';
import 'package:dpip/widgets/ui/labeled_divider.dart';

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

  // 定義地震類和氣象類圖層
  static const Set<MapLayer> _earthquakeLayers = {
    MapLayer.monitor,
    MapLayer.report,
    MapLayer.tsunami,
  };

  static const Set<MapLayer> _weatherLayers = {
    MapLayer.radar,
    MapLayer.temperature,
    MapLayer.precipitation,
    MapLayer.wind,
  };

  @override
  void didUpdateWidget(LayerToggleSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步父組件的狀態變化
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

  void _toggleLayer(MapLayer layer, bool checked) {
    // 如果是強震監視器且沒有其他圖層，不允許取消選中
    if (!checked && layer == MapLayer.monitor && _activeLayers.length == 1) {
      return;
    }
    
    widget.onLayerToggled(layer);
    setState(() {
      if (checked) {
        // 檢查互斥性
        if (_earthquakeLayers.contains(layer)) {
          // 地震類圖層互斥，清除所有其他地震類圖層
          _activeLayers.removeAll(_earthquakeLayers);
          // 同時清除氣象類圖層
          _activeLayers.removeAll(_weatherLayers);
        } else if (_weatherLayers.contains(layer)) {
          // 氣象類圖層可以複選，但要清除地震類圖層
          _activeLayers.removeAll(_earthquakeLayers);
        }
        _activeLayers.add(layer);
      } else {
        _activeLayers.remove(layer);
        
        // 只有在氣象類圖層取消且沒有其他氣象類圖層時，才回到強震監視器
        if (_weatherLayers.contains(layer)) {
          final hasOtherWeatherLayers = _activeLayers.any((l) => _weatherLayers.contains(l));
          if (!hasOtherWeatherLayers) {
            _activeLayers.add(MapLayer.monitor);
          }
        }
        // 如果取消的是地震類圖層（非強震監視器），回到強震監視器
        else if (_earthquakeLayers.contains(layer) && layer != MapLayer.monitor) {
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
      description: '地震類與氣象類圖層互斥'.i18n,
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
                onChanged: (checked) => _toggleLayer(MapLayer.tsunami, checked),
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
