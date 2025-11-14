import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

class MapStyle {
  late Map<String, dynamic> json;

  MapStyle(BuildContext context, {required BaseMapType baseMap}) {
    json = {
      'version': 8,
      'name': 'DPIP Map',
      'center': DpipMap.kTaiwanCenter.asGeoJsonCooridnate,
      'zoom': DpipMap.adjustedZoom(context, DpipMap.kTaiwanZoom),
      'font-faces': {
        'Noto Sans TC Regular':
            'https://cdn.jsdelivr.net/gh/notofonts/noto-cjk/Sans/OTF/TraditionalChinese/NotoSansCJKtc-Regular.otf',
        'Noto Sans TC Bold':
            'https://cdn.jsdelivr.net/gh/notofonts/noto-cjk/Sans/OTF/TraditionalChinese/NotoSansCJKtc-Bold.otf',
      },
      'glyphs': 'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf',
      'sprite': 'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/sprites',
      'sources': {...osmSource(), ...googleSource(), ...exptechSource(), ...locationSource()},
      'layers': [
        background(),
        ...osmLayers(context.colors, visible: baseMap == BaseMapType.osm),
        ...googleLayers(visible: baseMap == BaseMapType.google),
        ...exptechLayers(context.colors, visible: baseMap == BaseMapType.exptech),
        locationLayer(),
      ],
    };
  }

  Future<String> save() async {
    final cache = await getApplicationCacheDirectory();
    final cachePath = cache.path;

    final data = jsonEncode(json);
    final hash = md5.convert(utf8.encode(data)).toString();

    final styleJsonFile = File('$cachePath/map-$hash.json');

    if (!styleJsonFile.existsSync()) {
      await styleJsonFile.writeAsString(data);
    }

    return styleJsonFile.path;
  }

  static Map<String, dynamic> osmSource() => {
    'ne2_shaded': {
      'maxzoom': 6,
      'tileSize': 256,
      'tiles': ['https://tiles.openfreemap.org/natural_earth/ne2sr/{z}/{x}/{y}.png'],
      'type': 'raster',
    },
    'openmaptiles': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet', 'volatile': true},
  };

  static Map<String, dynamic> background() => {
    'id': 'background',
    'type': 'background',
    'paint': {'background-opacity': 0},
    'layout': {'visibility': 'visible'},
  };

  static List<Map<String, dynamic>> osmLayers(ColorScheme colors, {bool visible = false}) => [
    {
      'id': 'osm-landcover-glacier',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'landcover',
      'filter': [
        '==',
        ['get', 'subclass'],
        'glacier',
      ],
      'paint': {
        'fill-color': '#fff',
        'fill-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          0,
          0.9,
          10,
          0.3,
        ],
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-park',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'park',
      'filter': [
        'match',
        ['geometry-type'],
        ['MultiPolygon', 'Polygon'],
        true,
        false,
      ],
      'paint': {
        'fill-color': '#d8e8c8',
        'fill-opacity': [
          'interpolate',
          ['exponential', 1.8],
          ['zoom'],
          9,
          if (colors.brightness == Brightness.dark) 0.05 else 0.6,
          12,
          if (colors.brightness == Brightness.dark) 0.004 else 0.25,
        ],
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-landcover-wood',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'landcover',
      'filter': [
        '==',
        ['get', 'class'],
        'wood',
      ],
      'paint': {
        'fill-antialias': [
          'step',
          ['zoom'],
          false,
          9,
          true,
        ],
        'fill-color': '#66aa44',
        'fill-opacity': 0.1,
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-landcover-grass',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'landcover',
      'filter': [
        '==',
        ['get', 'class'],
        'grass',
      ],
      'paint': {'fill-color': '#d2e8c2', 'fill-opacity': colors.brightness == Brightness.dark ? 0.2 : 1},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-landcover-grass-park',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'park',
      'filter': [
        '==',
        ['get', 'class'],
        'public_park',
      ],
      'paint': {'fill-color': '#d8e8c8', 'fill-opacity': colors.brightness == Brightness.dark ? 0.4 : 0.8},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway_tunnel',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'minzoom': 14,
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          ['canal', 'river', 'stream'],
          true,
          false,
        ],
        [
          '==',
          ['get', 'brunnel'],
          'tunnel',
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-dasharray': [2, 4],
        'line-width': [
          'interpolate',
          ['exponential', 1.3],
          ['zoom'],
          13,
          0.5,
          20,
          6,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-other',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          ['canal', 'river', 'stream'],
          false,
          true,
        ],
        [
          '==',
          ['get', 'intermittent'],
          0,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-width': [
          'interpolate',
          ['exponential', 1.3],
          ['zoom'],
          13,
          0.5,
          20,
          2,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-other-intermittent',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          ['canal', 'river', 'stream'],
          false,
          true,
        ],
        [
          '==',
          ['get', 'intermittent'],
          1,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-dasharray': [4, 3],
        'line-width': [
          'interpolate',
          ['exponential', 1.3],
          ['zoom'],
          13,
          0.5,
          20,
          2,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-stream-canal',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          ['canal', 'stream'],
          true,
          false,
        ],
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
        [
          '==',
          ['get', 'intermittent'],
          0,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-width': [
          'interpolate',
          ['exponential', 1.3],
          ['zoom'],
          13,
          0.5,
          20,
          6,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-stream-canal-intermittent',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          ['canal', 'stream'],
          true,
          false,
        ],
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
        [
          '==',
          ['get', 'intermittent'],
          1,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-dasharray': [4, 3],
        'line-width': [
          'interpolate',
          ['exponential', 1.3],
          ['zoom'],
          13,
          0.5,
          20,
          6,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-river',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'river',
        ],
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
        [
          '!=',
          ['get', 'intermittent'],
          1,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-width': [
          'interpolate',
          ['exponential', 1.2],
          ['zoom'],
          10,
          0.8,
          20,
          6,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway-river-intermittent',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'river',
        ],
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
        [
          '==',
          ['get', 'intermittent'],
          1,
        ],
      ],
      'paint': {
        'line-color': '#a0c8f0',
        'line-opacity': colors.brightness == Brightness.dark ? 0.4 : 1,
        'line-dasharray': [3, 2.5],
        'line-width': [
          'interpolate',
          ['exponential', 1.2],
          ['zoom'],
          10,
          0.8,
          20,
          6,
        ],
      },
      'layout': {'line-cap': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-water',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'water',
      'filter': [
        'all',
        [
          '!=',
          ['get', 'intermittent'],
          1,
        ],
        [
          '!=',
          ['get', 'brunnel'],
          'tunnel',
        ],
      ],
      'paint': {
        'fill-color': colors.brightness == Brightness.dark ? colors.surfaceContainer.toHexStringRGB() : '#AECFE2',
        'fill-outline-color': colors.brightness == Brightness.dark ? colors.outline.toHexStringRGB() : '#AECFE2',
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-water-intermittent',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'water',
      'filter': [
        '==',
        ['get', 'intermittent'],
        1,
      ],
      'paint': {'fill-color': '#CFE6F7', 'fill-opacity': colors.brightness == Brightness.dark ? 0.3 : 0.7},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-landcover-ice-shelf',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'landcover',
      'filter': [
        '==',
        ['get', 'subclass'],
        'ice_shelf',
      ],
      'paint': {
        'fill-color': colors.brightness == Brightness.dark ? colors.surfaceContainerHigh.toHexStringRGB() : '#fff',
        'fill-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          0,
          0.9,
          10,
          0.3,
        ],
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-landcover-sand',
      'type': 'fill',
      'source': 'openmaptiles',
      'source-layer': 'landcover',
      'filter': [
        '==',
        ['get', 'class'],
        'sand',
      ],
      'paint': {'fill-color': '#f5eebc', 'fill-opacity': colors.brightness == Brightness.dark ? 0.6 : 1},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-boundary_3',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'boundary',
      'minzoom': 4,
      'filter': [
        'all',
        [
          '>=',
          ['get', 'admin_level'],
          3,
        ],
        [
          '<=',
          ['get', 'admin_level'],
          6,
        ],
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
        [
          '!=',
          ['get', 'disputed'],
          1,
        ],
        [
          '!',
          ['has', 'claimed_by'],
        ],
      ],
      'paint': {
        'line-color': colors.outline.toHexStringRGB(),
        'line-dasharray': [1, 1],
        'line-width': [
          'interpolate',
          ['linear', 1],
          ['zoom'],
          7,
          1,
          11,
          2,
        ],
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-boundary_2',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'boundary',
      'filter': [
        'all',
        [
          '==',
          ['get', 'admin_level'],
          2,
        ],
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
        [
          '!=',
          ['get', 'disputed'],
          1,
        ],
        [
          '!',
          ['has', 'claimed_by'],
        ],
      ],
      'paint': {
        'line-color': colors.outlineVariant.toHexStringRGB(),
        'line-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          0,
          0.4,
          4,
          1,
        ],
        'line-width': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3,
          1,
          5,
          1.2,
          12,
          3,
        ],
      },
      'layout': {'line-cap': 'round', 'line-join': 'round', 'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-boundary_disputed',
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'boundary',
      'filter': [
        'all',
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
        [
          '==',
          ['get', 'disputed'],
          1,
        ],
      ],
      'paint': {
        'line-color': colors.outlineVariant.toHexStringRGB(),
        'line-dasharray': [1, 2],
        'line-width': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3,
          1,
          5,
          1.2,
          12,
          3,
        ],
      },
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': 'osm-waterway_line_label',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'waterway',
      'minzoom': 10,
      'filter': [
        'match',
        ['geometry-type'],
        ['LineString', 'MultiLineString'],
        true,
        false,
      ],
      'paint': {
        'text-color': '#74aee9',
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1.5,
      },
      'layout': {
        'symbol-placement': 'line',
        'symbol-spacing': 350,
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Regular'],
        'text-letter-spacing': 0.2,
        'text-max-width': 5,
        'text-size': 14,
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-water_name_line_label',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'water_name',
      'filter': [
        'match',
        ['geometry-type'],
        ['LineString', 'MultiLineString'],
        true,
        false,
      ],
      'paint': {
        'text-color': '#495e91',
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1.5,
      },
      'layout': {
        'symbol-placement': 'line',
        'symbol-spacing': 350,
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Regular'],
        'text-letter-spacing': 0.2,
        'text-max-width': 5,
        'text-size': 14,
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_country_2',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'maxzoom': 9,
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'country',
        ],
        [
          '==',
          ['get', 'rank'],
          2,
        ],
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Bold'],
        'text-max-width': 6.25,
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          2,
          9,
          5,
          17,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_town',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'minzoom': 6,
      'filter': [
        '==',
        ['get', 'class'],
        'town',
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'icon-allow-overlap': true,
        'icon-image': [
          'step',
          ['zoom'],
          'circle_11_black',
          10,
          '',
        ],
        'icon-optional': false,
        'icon-size': 0.2,
        'text-anchor': 'bottom',
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Regular'],
        'text-max-width': 8,
        'text-size': [
          'interpolate',
          ['exponential', 1.2],
          ['zoom'],
          7,
          12,
          11,
          14,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_state',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'minzoom': 5,
      'maxzoom': 8,
      'filter': [
        '==',
        ['get', 'class'],
        'state',
      ],
      'paint': {
        'text-color': colors.onSurfaceVariant.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Regular'],
        'text-letter-spacing': 0.2,
        'text-max-width': 9,
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          10,
          8,
          14,
        ],
        'text-transform': 'uppercase',
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_city',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'minzoom': 3,
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'city',
        ],
        [
          '!=',
          ['get', 'capital'],
          2,
        ],
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'icon-allow-overlap': true,
        'icon-image': [
          'step',
          ['zoom'],
          'circle_11_black',
          9,
          '',
        ],
        'icon-optional': false,
        'icon-size': 0.4,
        'text-anchor': 'bottom',
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Regular'],
        'text-max-width': 8,
        'text-offset': [0, -0.1],
        'text-size': [
          'interpolate',
          ['exponential', 1.2],
          ['zoom'],
          4,
          11,
          7,
          13,
          11,
          18,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_city_capital',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'minzoom': 3,
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'city',
        ],
        [
          '==',
          ['get', 'capital'],
          2,
        ],
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'icon-allow-overlap': true,
        'icon-image': [
          'step',
          ['zoom'],
          'circle_11_black',
          9,
          '',
        ],
        'icon-optional': false,
        'icon-size': 0.5,
        'text-anchor': 'bottom',
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Bold'],
        'text-max-width': 8,
        'text-offset': [0, -0.2],
        'text-size': [
          'interpolate',
          ['exponential', 1.2],
          ['zoom'],
          4,
          12,
          7,
          14,
          11,
          20,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_country_3',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'minzoom': 2,
      'maxzoom': 9,
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'country',
        ],
        [
          '>=',
          ['get', 'rank'],
          3,
        ],
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Bold'],
        'text-max-width': 6.25,
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3,
          9,
          7,
          17,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
    {
      'id': 'osm-label_country_1',
      'type': 'symbol',
      'source': 'openmaptiles',
      'source-layer': 'place',
      'maxzoom': 9,
      'filter': [
        'all',
        [
          '==',
          ['get', 'class'],
          'country',
        ],
        [
          '==',
          ['get', 'rank'],
          1,
        ],
      ],
      'paint': {
        'text-color': colors.onSurface.toHexStringRGB(),
        'text-halo-blur': 1,
        'text-halo-color': colors.outlineVariant.toHexStringRGB(),
        'text-halo-width': 1,
      },
      'layout': {
        'text-field': [
          'coalesce',
          ['get', 'name:nonlatin'],
          ['get', 'name'],
        ],
        'text-font': ['Noto Sans TC Bold'],
        'text-max-width': 6.25,
        'text-size': [
          'interpolate',
          ['linear'],
          ['zoom'],
          1,
          9,
          4,
          17,
        ],
        'visibility': visible ? 'visible' : 'none',
      },
    },
  ];

  static Map<String, dynamic> googleSource() => {
    'google': {
      'type': 'raster',
      'tiles': ['https://mt1.google.com/vt/lyrs=s&hl=zh-TW&x={x}&y={y}&z={z}'],
      'tileSize': 256,
      'attribution': '&copy; Google Maps',
      'maxzoom': 19,
    },
  };

  static List<Map<String, dynamic>> googleLayers({bool visible = false}) => [
    {
      'id': 'google-raster',
      'type': 'raster',
      'source': 'google',
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
  ];

  static Map<String, dynamic> exptechSource() => {
    'exptech': {
      'type': 'vector',
      'url': 'https://lb.exptech.dev/api/v1/map/tiles/tiles.json',
      'tileSize': 512,
      'buffer': 64,
    },
  };

  static List<Map<String, dynamic>> exptechLayers(ColorScheme colors, {bool visible = false}) => [
    {
      'id': BaseMapLayerIds.exptechGlobalFill,
      'type': 'fill',
      'source': 'exptech',
      'source-layer': 'global',
      'paint': {'fill-color': colors.surfaceContainer.toHexStringRGB(), 'fill-opacity': 1},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': BaseMapLayerIds.exptechCountyFill,
      'type': 'fill',
      'source': 'exptech',
      'source-layer': 'city',
      'paint': {'fill-color': colors.surfaceContainerHigh.toHexStringRGB(), 'fill-opacity': 1},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': BaseMapLayerIds.exptechTownFill,
      'type': 'fill',
      'source': 'exptech',
      'source-layer': 'town',
      'paint': {'fill-color': colors.surfaceContainerHigh.toHexStringRGB(), 'fill-opacity': 1},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
    {
      'id': BaseMapLayerIds.exptechCountyOutline,
      'type': 'line',
      'source': 'exptech',
      'source-layer': 'city',
      'paint': {'line-color': colors.outline.toHexStringRGB()},
      'layout': {'visibility': visible ? 'visible' : 'none'},
    },
  ];

  static Map<String, dynamic> locationSource() => {
    'user-location': {'type': 'geojson', 'data': GeoJsonBuilder.empty},
  };

  static Map<String, dynamic> locationLayer() => {
    'id': 'user-location',
    'type': 'symbol',
    'source': 'user-location',
    'layout': {
      'icon-image': 'gps',
      'icon-size': kSymbolIconSize,
      'icon-allow-overlap': true,
      'icon-ignore-placement': true,
    },
  };
}
