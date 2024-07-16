import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'map_config.dart';

part 'map_style.g.dart';

@riverpod
MapStyle mapStyle(MapStyleRef ref) => MapStyle();

class MapStyle {
  Future<String> _saveStyleJson(
    Map<String, dynamic> json,
    String prefix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final documentDir = dir.path;
    final stylesDir = '$documentDir/styles';

    await Directory(stylesDir).create(recursive: true);
    final styleFile = File('$stylesDir/${prefix}style.json');
    await styleFile.writeAsString(jsonEncode(json));
    return styleFile.path;
  }

  Future<String> getStyle({
    required bool isDark,
    required ColorScheme scheme,
  }) async {
    if (kIsWeb) {
      return 'https://map.eqmonitor.app/tiles/style.json';
    }
    final colorScheme = isDark ? MapColorScheme.dark(colorScheme: scheme) : MapColorScheme.light(colorScheme: scheme);
    final json = {
      'version': 8,
      'name': 'EQMonitor Style',
      'center': [50, 10],
      'zoom': 4,
      'sources': {
        'eqmonitor_map': {
          'type': 'vector',
          'url': 'https://map.eqmonitor.app/tiles/tiles.json',
        },
      },
      'sprite': '',
      'glyphs': 'https://orangemug.github.io/font-glyphs/glyphs/{fontstack}/{range}.pbf',
      'layers': [
        {
          'id': BaseLayer.background.name,
          'type': 'background',
          'paint': {
            'background-color': colorScheme.backgroundColor.toHexStringRGB(),
          },
        },
        {
          'id': BaseLayer.countriesFill.name,
          'source': 'eqmonitor_map',
          'source-layer': 'countries',
          'type': 'fill',
          'layout': {'visibility': 'visible'},
          'paint': {
            'fill-color': colorScheme.worldLandColor.toHexStringRGB(),
          },
        },
        {
          'id': BaseLayer.countriesLines.name,
          'source': 'eqmonitor_map',
          'source-layer': 'countries',
          'type': 'line',
          'layout': {'visibility': 'visible'},
          'paint': {
            'line-color': colorScheme.worldLineColor.toHexStringRGB(),
            'line-width': [
              'interpolate',
              ['linear'],
              ['zoom'],
              3,
              0.5,
              5.5,
              1,
            ],
          },
        },
        {
          'id': BaseLayer.areaForecastLocalEFill.name,
          'source': 'eqmonitor_map',
          'source-layer': 'areaForecastLocalE',
          'type': 'fill',
          'paint': {
            'fill-color': colorScheme.japanLandColor.toHexStringRGB(),
          },
        },
        // areaForecastLocalEew_line
        {
          'id': BaseLayer.areaForecastLocalEewLine.name,
          'source': 'eqmonitor_map',
          'source-layer': 'areaForecastLocalEew',
          'type': 'line',
          'layout': {'line-cap': 'round', 'line-join': 'round'},
          'paint': {
            'line-color': colorScheme.japanLineColor.toHexStringRGB(),
            'line-width': [
              'interpolate',
              ['linear'],
              ['zoom'],
              3,
              0.5,
              5.5,
              1,
            ],
          },
        },
        {
          'id': BaseLayer.areaForecastLocalELine.name,
          'source': 'eqmonitor_map',
          'source-layer': 'areaForecastLocalE',
          'type': 'line',
          'layout': {'line-cap': 'round', 'line-join': 'round'},
          'paint': {
            'line-color': colorScheme.japanLineColor.toHexStringRGB(),
            'line-opacity': [
              'interpolate',
              ['linear'],
              ['zoom'],
              3,
              0,
              5,
              0.2,
              5.5,
              1,
            ],
            'line-width': 0.5,
          },
        },
        // areaInformationCityQuake
        {
          'id': BaseLayer.areaInformationCityQuakeLine.name,
          'source': 'eqmonitor_map',
          'source-layer': 'areaInformationCityQuake',
          'type': 'line',
          'layout': {'line-cap': 'round', 'line-join': 'round'},
          'paint': {
            'line-color': colorScheme.japanLineColor.toHexStringRGB(),
            'line-width': 0.5,
            'line-opacity': [
              'interpolate',
              ['linear'],
              ['zoom'],
              7,
              0,
              9.5,
              0.3,
            ],
          },
        },
      ],
    };
    return _saveStyleJson(json, 'maplibre-$isDark');
  }
}

enum BaseLayer {
  background,
  countriesLines,
  countriesFill,
  areaForecastLocalEFill,
  areaForecastLocalEewLine,
  areaForecastLocalELine,
  areaInformationCityQuakeLine,
}
