/// The tile-URL helpers must be invisible: every memoised or precompiled
/// answer has to equal the one the plain string/URI code gave before.
library;

import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:dpip/shared/map/tile_url.dart';
import 'package:dpip/shared/map/xyz_tiles.dart';
import 'package:flutter_test/flutter_test.dart';

/// A spread of URLs the memo may see: real tiles of several families, the
/// same frame at many coordinates, and every shape that must fall through to
/// the direct derivation (queries, non-numeric frames or coordinates, no
/// scheme, too few segments, an uppercase host the parser normalises).
const List<String> _urls = [
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/106/55.webp',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/107/55.webp',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/6/53/27.webp',
  'https://static.exptech.dev/api/v2/tiles/radar/1787237400/7/106/55.webp',
  'https://static.exptech.dev/api/v2/tiles/satellite/13/normal/1787236800/'
      '7/106/55.webp',
  'https://static.exptech.dev/api/v2/tiles/wind/gfs/1787239200/1787236800/'
      '5/26/13.webp',
  'https://static.exptech.dev/api/v2/tiles/dpm/aed/12/3421/1740.mvt',
  'https://static.lb.exptech.dev/api/v1/map/tiles/7/1/1.pbf',
  'https://static.lb.exptech.dev/api/v1/map/terrain/7/107/55.png',
  'https://static.lb.exptech.dev/api/v1/map/gsi/14/13700/7000.pbf',
  'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/Noto/0-255.pbf',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/106/55.webp'
      '?style=jma',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/106/55.webp'
      '#frag',
  'https://static.exptech.dev/api/v2/tiles/radar/old/2/3/4.webp',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/x/55.webp',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/7/106/55',
  'https://static.exptech.dev/api/v2/tiles/radar/1787236800/106/55.webp',
  'https://STATIC.EXPTECH.DEV/api/v2/tiles/radar/1787236800/7/106/55.webp',
  'https://example.com/other/1787236800/7/106/55.webp',
  '//static.exptech.dev/api/v2/tiles/radar/1787236800/7/106/55.webp',
  '/api/v2/tiles/radar/1787236800/7/106/55.webp',
  '1/2/3.png',
  '',
];

void main() {
  group('tileUrlDirectoryEnd', () {
    test('finds the directory of a plain z/x/y.ext tail', () {
      const url = 'https://h/api/v2/tiles/radar/1787236800/7/106/55.webp';
      final end = tileUrlDirectoryEnd(url);
      expect(url.substring(0, end), 'https://h/api/v2/tiles/radar/1787236800/');
    });

    test(
      'refuses anything that is not three decimal runs and an extension',
      () {
        for (final url in const [
          'https://h/a/7/106/55.webp?style=jma',
          'https://h/a/7/106/55.webp#f',
          'https://h/a/7/x/55.webp',
          'https://h/a/7/106/55',
          'https://h/a/106/55.webp',
          'https://h/a/7/106/55.',
          'https://h/a/7/106/.webp',
          'https://h/a7/106/55.webp',
          '1/2/3.png',
          '',
        ]) {
          expect(tileUrlDirectoryEnd(url), -1, reason: url);
        }
      },
    );
  });

  group('TileUrlMemo', () {
    test('derives once per directory and never caches a non-plain tail', () {
      final seen = <String>[];
      final memo = TileUrlMemo<int>((url) {
        seen.add(url);
        return url.length;
      });
      const a = 'https://h/f/1/2/3.png';
      const b = 'https://h/f/1/2/4.png';
      const q = 'https://h/f/1/2/4.png?x';
      expect(memo(a), a.length);
      expect(memo(b), b.length);
      expect(memo(q), q.length);
      expect(memo(q), q.length);
      expect(seen, [a, q, q], reason: 'siblings share; queries never cache');
    });

    test('clears at capacity instead of growing without bound', () {
      var derived = 0;
      final memo = TileUrlMemo<int>((_) => ++derived, capacity: 2);
      memo('https://h/a/1/2/3.png');
      memo('https://h/b/1/2/3.png');
      memo('https://h/c/1/2/3.png');
      expect(memo('https://h/a/1/2/3.png'), 4, reason: 'a was evicted');
    });
  });

  group('frame prefix memo', () {
    test('agrees with the direct parse for every URL shape', () {
      for (final url in _urls) {
        expect(
          MapTileWarmer.framePrefixOf(url),
          MapTileWarmer.parseFramePrefix(url),
          reason: url,
        );
      }
    });

    test('a sibling served from the memo still gets the parsed answer', () {
      const frame = 'https://h/api/v2/tiles/radar/1787236800/';
      const first = '${frame}7/106/55.webp';
      const sibling = '${frame}9/423/221.webp';
      expect(MapTileWarmer.framePrefixOf(first), frame);
      expect(
        MapTileWarmer.framePrefixOf(sibling),
        MapTileWarmer.parseFramePrefix(sibling),
      );
      // A query string is not a plain tail, so it goes through the parser
      // itself — and there the path still matches, exactly as it always did.
      expect(MapTileWarmer.framePrefixOf('$first?style=jma'), frame);
    });
  });

  group('tile gate memo', () {
    test('agrees with the direct parse for every URL shape', () {
      for (final url in _urls) {
        expect(
          MapTileCache.isTileUrl(url),
          MapTileCache.parseIsTile(url),
          reason: url,
        );
      }
    });

    test('no immutable marker can be matched by a plain z/x/y tail', () {
      // The memo's exactness rests on this: a marker ending in a letter then
      // `/` can neither sit inside a run of digits nor be completed by one,
      // so swapping one plain tail for another never changes the answer. A
      // marker like `/api/v1/` would break that — it would end in `1/`.
      for (final marker in EtagInterceptor.immutableAssetMarkers) {
        expect(
          RegExp(r'[A-Za-z]/$').hasMatch(marker),
          isTrue,
          reason: '$marker must end in a letter followed by "/"',
        );
      }
    });
  });

  group('TileUrlTemplate', () {
    String reference(String template, XyzTile tile) => template
        .replaceFirst('{z}', '${tile.z}')
        .replaceFirst('{x}', '${tile.x}')
        .replaceFirst('{y}', '${tile.y}');

    const tiles = <XyzTile>[
      (z: 0, x: 0, y: 0),
      (z: 7, x: 106, y: 55),
      (z: 12, x: 3421, y: 1740),
    ];

    test('expands exactly as the replaceFirst chain did', () {
      for (final template in const [
        'https://h/api/v2/tiles/radar/1787236800/{z}/{x}/{y}.webp',
        'https://h/api/v2/tiles/satellite/13/jma/1787236800/{z}/{x}/{y}.webp'
            '?style=jma',
        'https://h/{y}/{x}/{z}.png',
        'https://h/{z}/{z}/{x}/{y}.png',
        'https://h/{x}/{y}.png',
        'https://h/{z}{x}{y}',
        '{z}',
        'https://h/no/placeholders.png',
        '',
      ]) {
        final compiled = TileUrlTemplate(template);
        for (final tile in tiles) {
          expect(
            compiled.expand(tile),
            reference(template, tile),
            reason: '$template @ $tile',
          );
        }
      }
    });
  });
}
