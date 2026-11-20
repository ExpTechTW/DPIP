/// The region-host arithmetic behind the tile cache and tile failover.
///
/// Both functions are what make one tile one tile, whichever region host the
/// URL in front of it names. A key that drifted from what an installed app
/// already stored orphans its whole map cache without a single error; a route
/// that drifted from `ApiClient.hostsFor` fails over into a host nothing else
/// uses.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/network/tile_hosts.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const radarPath = '/api/v2/tiles/radar/1783360200/7/107/55.webp';
  const qpesumsPath = '/api/v2/tiles/qpesums/1783360200/7/107/55.webp';
  const dpmPath = '/api/v2/tiles/dpm/aed/10/857/438.mvt';
  const satellitePath =
      '/api/v2/tiles/satellite/13/normal/1783360200/5/26/14.webp';
  const windPath = '/api/v2/tiles/wind/gfs/1783339200/1783360200/5/26/14.webp';
  const tnn1 = 'https://static.core-tnn1.exptech.dev';
  const tyo1 = 'https://static.core-tyo1.exptech.dev';

  group('tileCacheKey', () {
    test('keys both core regions on tnn1, where installed caches are', () {
      for (final path in [radarPath, qpesumsPath, dpmPath]) {
        expect(tileCacheKey('$tyo1$path'), '$tnn1$path');
        expect(tileCacheKey('$tnn1$path'), '$tnn1$path');
      }
    });

    test('keys every LB region on the bare host installed caches use', () {
      for (final path in [
        '/api/v1/map/tiles/7/107/55.pbf',
        '/api/v1/map/gsi/14/13703/7034.pbf',
        '/api/v1/map/terrain/7/107/55.png',
      ]) {
        for (final region in LbRegion.values) {
          expect(
            tileCacheKey('https://static.lb-${region.code}.exptech.dev$path'),
            '$lbStaticKeyOrigin$path',
          );
        }
        expect(
          tileCacheKey('$lbStaticKeyOrigin$path'),
          '$lbStaticKeyOrigin$path',
        );
      }
    });

    test('leaves every other URL as its own key', () {
      for (final url in [
        'https://api.core-tyo1.exptech.dev/api/v2/tiles/radar/list',
        'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/glyphs/0-255.pbf',
        'https://avatars.githubusercontent.com/u/1?v=4',
        // A lookalike that merely starts with a region origin.
        'https://static.core-tyo1.exptech.dev.example.com/api/v2/tiles/radar/1/1/1/1.webp',
        tyo1,
      ]) {
        expect(tileCacheKey(url), url);
      }
    });
  });

  group('tileRoute', () {
    test('routes the replicated core families along coreStatic', () {
      for (final origin in [tnn1, tyo1]) {
        for (final path in [radarPath, qpesumsPath, dpmPath]) {
          expect(tileRoute('$origin$path'), (
            tier: ApiTier.coreStatic,
            path: path,
            notFoundFailsOver: true,
          ));
        }
      }
    });

    test('routes the basemap, OSM and terrain along lbStatic', () {
      const path = '/api/v1/map/tiles/7/107/55.pbf';
      for (final region in LbRegion.values) {
        expect(tileRoute('https://static.lb-${region.code}.exptech.dev$path'), (
          tier: ApiTier.lbStatic,
          path: path,
          notFoundFailsOver: false,
        ));
      }
      expect(
        tileRoute('$lbStaticKeyOrigin$path'),
        isNull,
        reason: 'the bare host is a key, never a request',
      );
    });

    test('has no route for a family only tnn1 carries', () {
      for (final path in [satellitePath, windPath]) {
        expect(tileRoute('$tnn1$path'), isNull);
      }
    });

    test('has no route off the region hosts', () {
      expect(
        tileRoute('https://api.core-tnn1.exptech.dev/api/v2/tiles/radar/list'),
        isNull,
      );
      expect(tileRoute('https://example.com$radarPath'), isNull);
    });

    test('names exactly the hosts ApiClient fails over between', () {
      // A route is only as good as the hosts its tier resolves to: if the two
      // spellings drift, a failover asks a host nothing else uses.
      final regions = RegionSelection(SettingsStore.inMemory({}));
      final client = ApiClient(Dio(), regions);
      for (final core in CoreRegion.values) {
        regions.core = core;
        for (final origin in client.hostsFor(ApiTier.coreStatic)) {
          expect(tileRoute('$origin$radarPath')?.tier, ApiTier.coreStatic);
        }
      }
      for (final lb in LbRegion.values) {
        regions.lb = lb;
        expect(client.hostsFor(ApiTier.lbStatic).first, staticLbOrigin(lb));
        for (final origin in client.hostsFor(ApiTier.lbStatic)) {
          expect(
            tileRoute('$origin/api/v1/map/tiles/0/0/0.pbf')?.tier,
            ApiTier.lbStatic,
          );
        }
      }
    });
  });
}
