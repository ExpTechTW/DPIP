/// The committed basemap bundle is what `tool/gen/basemap_seed.dart` says it
/// is: every tile the coverage names, in order, packed without gaps, each one
/// a gzip member that inflates, under a version that matches the bytes.
///
/// The generator cannot import Flutter code, so this is also where its copy of
/// the basemap URL is held to the one the style actually requests.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/shared/map/basemap_seed.g.dart';
import 'package:dpip/shared/map/basemap_seed_format.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const seed = bundledBasemapSeed;

  group('coverage', () {
    test('Taiwan at z0–9 and the world at z0–2 is 122 tiles', () {
      final tiles = basemapSeedCoverage(
        (west: 118.0, south: 21.7, east: 122.2, north: 26.5),
        minZoom: 0,
        maxZoom: 9,
        worldMaxZoom: 2,
      );
      // 104 over Taiwan (measured against the origin), 21 for the world, and
      // the three world tiles that also hold Taiwan counted once.
      expect(tiles, hasLength(122));
      expect(tiles.toSet(), hasLength(tiles.length), reason: 'no duplicates');
    });

    test('it reaches the outlying islands at the deepest zoom', () {
      final z9 = basemapSeedCoverage(
        seed.bounds,
        minZoom: seed.maxZoom,
        maxZoom: seed.maxZoom,
        worldMaxZoom: -1,
      ).toSet();
      // Kinmen, Matsu, Lanyu and Taipei, at z9.
      for (final (lon, lat) in [
        (118.32, 24.44),
        (119.95, 26.16),
        (121.55, 22.04),
        (121.56, 25.04),
      ]) {
        expect(z9, contains(_tile(lon, lat, 9)), reason: '$lon,$lat');
      }
    });
  });

  group('the committed bundle', () {
    test('was fetched from the URL the style requests', () {
      expect(
        seed.source,
        basemapOriginTileUrl,
        reason:
            'the tiles are stored under these URLs; a mismatch plants rows '
            'MapLibre never asks for',
      );
      expect(seed.maxZoom, basemapSourceMaxZoom.toInt());
    });

    test('holds exactly the coverage its constants name, in order', () {
      final indexed = [
        for (final part in seed.parts)
          for (final tile in part.tiles) (tile.z, tile.x, tile.y),
      ];
      expect(
        indexed,
        basemapSeedCoverage(
          seed.bounds,
          minZoom: seed.minZoom,
          maxZoom: seed.maxZoom,
          worldMaxZoom: seed.worldMaxZoom,
        ),
      );
    });

    test('packs every part without gaps and every tile inflates', () {
      final decoded = <({int z, int x, int y, List<int> bytes})>[];
      for (final part in seed.parts) {
        final file = File(part.asset);
        expect(file.existsSync(), isTrue, reason: part.asset);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, part.bytes, reason: '${part.asset} size');

        var offset = 0;
        for (final tile in part.tiles) {
          expect(tile.offset, offset, reason: 'gap before $tile');
          offset += tile.length;
          final member = Uint8List.sublistView(
            bytes,
            tile.offset,
            tile.offset + tile.length,
          );
          if (member.isNotEmpty) {
            expect(member.take(2), [0x1f, 0x8b], reason: '$tile is gzip');
            expect(
              member[9],
              0xff,
              reason: 'the OS byte is fixed so packing is reproducible',
            );
          }
          decoded.add((
            z: tile.z,
            x: tile.x,
            y: tile.y,
            bytes: member.isEmpty ? const [] : gzip.decode(member),
          ));
        }
        expect(offset, part.bytes, reason: '${part.asset} tail');
      }

      expect(
        basemapSeedVersion(decoded),
        seed.version,
        reason: 'the version is what decides whether installed copies reseed',
      );
    });

    test('keeps every part inside the planting budget', () {
      for (final part in seed.parts) {
        expect(
          part.bytes <= 256 * 1024 || part.tiles.length == 1,
          isTrue,
          reason: '${part.asset} is ${part.bytes} bytes',
        );
      }
    });
  });

  group('version', () {
    final tiles = [
      (z: 0, x: 0, y: 0, bytes: const [1, 2, 3]),
      (z: 1, x: 1, y: 0, bytes: const <int>[]),
    ];

    test('is stable for the same tiles', () {
      expect(basemapSeedVersion(tiles), basemapSeedVersion(tiles));
      expect(basemapSeedVersion(tiles), matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('changes with any byte, address or emptiness', () {
      final base = basemapSeedVersion(tiles);
      expect(
        basemapSeedVersion([
          (z: 0, x: 0, y: 0, bytes: const [1, 2, 4]),
          tiles[1],
        ]),
        isNot(base),
      );
      expect(
        basemapSeedVersion([
          tiles[0],
          (z: 1, x: 0, y: 0, bytes: const <int>[]),
        ]),
        isNot(base),
      );
      expect(
        basemapSeedVersion([
          tiles[0],
          (z: 1, x: 1, y: 0, bytes: const [0]),
        ]),
        isNot(base),
      );
    });
  });
}

(int, int, int) _tile(double lon, double lat, int z) {
  final tiles = basemapSeedCoverage(
    (west: lon, south: lat, east: lon, north: lat),
    minZoom: z,
    maxZoom: z,
    worldMaxZoom: -1,
  );
  return tiles.single;
}
