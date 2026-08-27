import 'dart:convert';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the vector style parses and layers stack in order', () {
    final style = jsonDecode(
      exptechVectorStyle(
        MapColors.dark,
        basemapTileUrl: 'https://example.com/{z}/{x}/{y}.pbf',
        glyphsUrl: 'https://example.com/{fontstack}/{range}.pbf',
      ),
    ) as Map<String, dynamic>;

    final base = style['sources']['exptech'] as Map<String, dynamic>;
    expect(base['minzoom'], 0);
    expect(base['maxzoom'], basemapSourceMaxZoom);

    final layers = style['layers'] as List<dynamic>;
    final ids = [for (final l in layers) (l as Map<String, dynamic>)['id']];
    expect(ids, [
      'bg',
      'land',
      'county',
      'town',
      'town-outline',
      'county-outline',
      'town-label',
    ]);
  });

  test('terrain adds a mapbox-encoded raster-dem source and hillshade between fills and borders', () {
    final style = jsonDecode(
      exptechVectorStyle(
        MapColors.dark,
        basemapTileUrl: 'https://example.com/{z}/{x}/{y}.pbf',
        glyphsUrl: 'https://example.com/{fontstack}/{range}.pbf',
        terrainTileUrl:
            'https://static.lb.exptech.dev/api/v1/map/terrain/{z}/{x}/{y}.png',
      ),
    ) as Map<String, dynamic>;

    final terrain = style['sources']['terrain'] as Map<String, dynamic>;
    expect(terrain['type'], 'raster-dem');
    expect(
      terrain['encoding'],
      'mapbox',
      reason:
          'the server tiles are Mapbox terrain-RGB — MapLibre decodes them '
          'natively, no app-side rewrite (see satellite-tiles-go/web)',
    );
    expect(terrain['tileSize'], 512);
    expect(
      terrain['minzoom'],
      0,
      reason:
          'the relief must render at every zoom — a minzoom would blank the '
          'hillshade out as the user zooms out, and the low-zoom DEM bill is '
          'tiny (a whole-island view is one or two 512px tiles, vs ~49 at a '
          'zoomed-in hillshade viewport)',
    );
    // z11 overzoom 與原生 z12 hillshade 的中位 SSIM 0.982、海拔 RMSE
    // 1.56m；z10 在山區已有明顯差異，因此只省掉最後一層。
    expect(terrain['maxzoom'], terrainSourceMaxZoom);
    expect(
      terrain['bounds'],
      [110, 10, 132, 35],
      reason:
          'the bounds must overshoot the DEM bbox so the hillshade edge '
          'never meets the plain background on screen',
    );

    final hillshade = (style['layers'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((l) => l['id'] == terrainHillshadeLayerId);
    final paint = hillshade['paint'] as Map<String, dynamic>;
    expect(paint['hillshade-illumination-direction'], 335);
    expect(paint['hillshade-exaggeration'], 0.3);

    final layers = style['layers'] as List<dynamic>;
    final ids = [for (final l in layers) (l as Map<String, dynamic>)['id']];
    expect(ids, [
      'bg',
      'land',
      'county',
      'town',
      terrainHillshadeLayerId,
      'town-outline',
      'county-outline',
      'town-label',
    ]);
  });

  group('town-label layer', () {
    Map<String, dynamic> townLabel() {
      final style = jsonDecode(
        exptechVectorStyle(
          MapColors.light,
          basemapTileUrl: 'https://example.com/{z}/{x}/{y}.pbf',
          glyphsUrl: 'https://example.com/{fontstack}/{range}.pbf',
        ),
      ) as Map<String, dynamic>;
      return (style['layers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((l) => l['id'] == townLabelLayerId);
    }

    test('reads the township name from the app GeoJSON point source', () {
      final layout = townLabel()['layout'] as Map<String, dynamic>;
      expect(layout['text-field'], ['get', 'name']);
      expect(layout['text-font'], ['Noto Sans TC Regular']);
      expect(layout['text-allow-overlap'], false);
    });

    test('is sourced from the GeoJSON points, never the tile polygons', () {
      // Reading names off the `town` polygon layer duplicates a township whose
      // polygon crosses a tile boundary (a centroid per clipped piece) — the
      // whole reason labels come from the app's own point directory instead.
      expect(townLabel()['source'], townLabelSourceId);
      expect(townLabel().containsKey('source-layer'), isFalse);
      expect(townLabel()['source'], isNot('exptech'));
    });

    test('is gated: not placed before min zoom, faded in by the fade zoom', () {
      final layer = townLabel();
      expect(layer['minzoom'], townLabelMinZoom);
      final paint = layer['paint'] as Map<String, dynamic>;
      final opacity = paint['text-opacity'] as List<Object?>;
      expect(opacity, contains(townLabelMinZoom));
      expect(opacity, contains(townLabelFadeZoom));
    });

    test('label colours come from the palette, not hardcoded at the layer', () {
      final paint = townLabel()['paint'] as Map<String, dynamic>;
      expect(paint['text-color'], MapColors.light.label);
      expect(paint['text-halo-color'], MapColors.light.labelHalo);
    });
  });

  group('townLabelGeoJson', () {
    final directory = TownDirectory.fromJson({
      '100': {
        'city': '臺北',
        'town': '中正',
        'lat': 25.03,
        'lng': 121.52,
        'cityLevel': '市',
        'townLevel': '區',
      },
      '900': {
        'city': '屏東',
        'town': '屏東',
        'lat': 22.68,
        'lng': 120.49,
        'cityLevel': '縣',
        'townLevel': '市',
      },
    });

    test('one point feature per township, named from the directory', () {
      final geojson =
          jsonDecode(townLabelGeoJson(directory)) as Map<String, dynamic>;
      final features = geojson['features'] as List<dynamic>;
      expect(features, hasLength(2));
      for (final feature in features.cast<Map<String, dynamic>>()) {
        expect(feature['type'], 'Feature');
        final geometry = feature['geometry'] as Map<String, dynamic>;
        expect(geometry['type'], 'Point');
        final props = feature['properties'] as Map<String, dynamic>;
        expect(props['name'], isA<String>());
      }
      final names = [
        for (final f in features)
          ((f as Map<String, dynamic>)['properties']
              as Map<String, dynamic>)['name'],
      ];
      expect(names, containsAll(['中正區', '屏東市']));
    });

    test('each township appears exactly once, whatever the tiles hold', () {
      // Regression: the vector tiles hold the same township twice (a polygon
      // clipped across a tile boundary, or a mislabelled neighbour) and the old
      // polygon-centroid labels rendered the name once per copy. The directory
      // is unique per code, so a name never duplicates.
      final codes = [
        for (final f
            in (jsonDecode(townLabelGeoJson(directory))
                    as Map<String, dynamic>)['features']
                as List<dynamic>)
          (((f as Map<String, dynamic>)['properties'])
              as Map<String, dynamic>)['name'],
      ];
      expect(codes.toSet().length, codes.length);
    });
  });
}
