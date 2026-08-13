import 'dart:convert';

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
    expect(terrain['minzoom'], 0);
    expect(terrain['maxzoom'], 12);
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

    test('reads the township TOWN property in Noto Sans TC', () {
      final layout = townLabel()['layout'] as Map<String, dynamic>;
      expect(layout['text-field'], ['get', 'TOWN']);
      expect(layout['text-font'], ['Noto Sans TC Regular']);
      expect(layout['text-allow-overlap'], false);
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
}
