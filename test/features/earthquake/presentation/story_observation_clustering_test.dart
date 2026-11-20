import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart' as geo;
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:dpip/features/earthquake/presentation/story_observation_clustering.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

const _fixtureDir =
    'test/features/earthquake/presentation/fixtures/story_reports';
const _channel = MethodChannel('com.exptech.dpip/map_snapshot');
const _seeds = [0, 1, 7, 17, 42, 241, 115057, 115075];
const _cases = [
  ('tnn1', '115057-2026-0825-150011', {1: 38, 2: 64, 3: 12, 4: 5}),
  ('tyo1', '115057-2026-0825-150011', {1: 39, 2: 64, 3: 12, 4: 5}),
  ('tyo1', '115074-2026-1030-043743', {1: 11, 2: 4, 3: 3}),
  ('tyo1', '115067-2026-0930-130027', {1: 81, 2: 15}),
  ('tyo1', '115075-2026-1101-162007', {1: 48, 2: 48, 3: 3}),
  ('tyo1', '115000-2026-0909-192104', {1: 1}),
  (
    'tyo1',
    '107022-2018-0206-235041',
    {1: 11, 2: 33, 3: 27, 4: 5, 5: 3, 6: 1, 9: 4},
  ),
  ('long', '115075-2026-1101-162007', {1: 48, 2: 48, 3: 3}),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  for (final (node, id, histogram) in _cases) {
    test(
      '$node/$id accounts for every source under input permutations',
      () async {
        final sourceReport = _loadReport(node == 'long' ? 'tyo1' : node, id);
        final report = node == 'long'
            ? sourceReport.copyWith(location: '臺灣東部外海與菲律賓海板塊交界附近海域')
            : sourceReport;
        expect(report.id, id);
        final sourceIds = {
          for (final area in report.list.entries)
            for (final station in area.value.town.entries)
              jsonEncode([area.key, station.key]): station.value,
        };
        expect(sourceIds, hasLength(histogram.values.reduce((a, b) => a + b)));
        expect({
          for (final level in sourceIds.values.map((v) => v.intensity).toSet())
            level: sourceIds.values.where((v) => v.intensity == level).length,
        }, histogram);
        if (report.serial == '115057') {
          expect(
            sourceIds['["臺北市","臺北市"]']?.intensity,
            node == 'tyo1' ? 1 : null,
          );
        }
        if (report.serial == '115067') {
          expect(report.longitude, 122.88);
          expect(
            sourceIds.values.map((v) => v.latitude).reduce(math.min),
            lessThan(22.1),
          );
          expect(
            sourceIds.values.map((v) => v.latitude).reduce(math.max),
            greaterThan(25.1),
          );
        }
        if (report.serial == '115075') {
          expect(sourceIds, contains('["臺東縣","蘭嶼"]'));
          expect(
            sourceIds.values.map((v) => v.latitude).reduce(math.max),
            greaterThan(25.6),
          );
        }
        final legacy = id.startsWith('107022');
        expect(Intensity.usesLegacyScale(report.originTimeUtc), legacy);
        final camera = _camera(report);
        final projections = {
          'epicenter': _project(report.latitude, report.longitude, camera),
          for (final station in sourceIds.entries)
            station.key: _project(
              station.value.latitude,
              station.value.longitude,
              camera,
            ),
        };

        Future<List<StoryStationMarker>> capture(
          EarthquakeReport input,
          Iterable<String> responseIds,
        ) async {
          messenger.setMockMethodCallHandler(_channel, (call) async {
            expect(call.method, 'captureWithProjection');
            final points = List<Map<Object?, Object?>>.from(
              call.arguments['points'] as List,
            );
            expect(
              points.map((p) => p['id']),
              unorderedEquals(projections.keys),
            );
            for (final point in points.where((p) => p['id'] != 'epicenter')) {
              final source = sourceIds[point['id']]!;
              expect(point['latitude'], source.latitude);
              expect(point['longitude'], source.longitude);
            }
            return {
              'logicalWidth': 360.0,
              'logicalHeight': 640.0,
              'pngWidth': 720,
              'pngHeight': 1280,
              'png': _pngHeader(),
              'points': {
                for (final key in responseIds)
                  key: [projections[key]!.dx, projections[key]!.dy],
              },
            };
          });
          final snapshot = await StoryMapSnapshot.capture(
            report: input,
            style: '{}',
            centerLatitude: camera.target.latitude,
            centerLongitude: camera.target.longitude,
            zoom: camera.zoom,
          );
          return snapshot.markers;
        }

        List<Object> verify(
          List<StoryMarkerCluster> clusters, {
          double? maxDiameterMetres,
        }) {
          final seen = <String>{};
          for (final group in clusters) {
            expect(group.anchor, same(group.members.first));
            expect(group.count, group.members.length);
            expect(
              group.maxIntensity,
              group.members.map((m) => m.intensity).reduce(math.max),
            );
            for (final member in group.members) {
              expect(
                seen.add(member.sourceId),
                isTrue,
                reason: member.sourceId,
              );
              expect(sourceIds, contains(member.sourceId));
              final source = sourceIds[member.sourceId]!;
              expect(
                (member.latitude, member.longitude, member.intensity),
                (source.latitude, source.longitude, source.intensity),
              );
              expect(member.position, projections[member.sourceId]);
              expect(
                (member.position - group.anchor.position).distance,
                lessThanOrEqualTo(40),
              );
            }
            if (maxDiameterMetres != null) {
              for (final (index, a) in group.members.indexed) {
                for (final b in group.members.skip(index + 1)) {
                  expect(_distance(a, b), lessThanOrEqualTo(maxDiameterMetres));
                }
              }
            }
          }
          expect(seen, unorderedEquals(sourceIds.keys));
          final maximum = clusters.map((c) => c.maxIntensity).reduce(math.max);
          expect(maximum, report.maxIntensity);
          if (legacy) {
            for (final group in clusters.where((c) => c.maxIntensity >= 5)) {
              final label = Intensity.displayForReport(
                group.maxIntensity,
                report.originTimeUtc,
              ).label;
              expect(label, {5: '5', 6: '6', 9: '7'}[group.maxIntensity]);
            }
          }
          return [
            for (final group in clusters)
              [
                group.anchor.sourceId,
                group.anchor.latitude,
                group.anchor.longitude,
                group.anchor.position,
                group.maxIntensity,
                group.count,
                group.members.map((m) => m.sourceId).toList(),
              ],
          ];
        }

        List<Object> verifyBoth(List<StoryStationMarker> markers) => [
          for (final limit in [null, storyD75MaxDiameterMetres])
            verify(
              clusterStoryObservations(markers, maxDiameterMetres: limit),
              maxDiameterMetres: limit,
            ),
        ];

        final baseline = verifyBoth(await capture(report, projections.keys));
        for (final seed in _seeds) {
          final random = math.Random(seed);
          final shuffledReport = _reorder(
            report,
            <T>(List<T> items) => items.shuffle(random),
          );
          final responseIds = projections.keys.toList()..shuffle(random);
          final markers = await capture(shuffledReport, responseIds);
          expect(verifyBoth(markers), baseline, reason: 'API seed $seed');
          expect(
            verifyBoth(markers.toList()..shuffle(random)),
            baseline,
            reason: 'marker seed $seed',
          );
        }
        final reversed = _reorder(
          report,
          <T>(List<T> items) => items.setAll(0, items.reversed.toList()),
        );
        expect(
          verifyBoth(
            await capture(reversed, projections.keys.toList().reversed),
          ),
          baseline,
          reason: 'all API and projection keys reversed',
        );
      },
    );
  }

  test(
    '75 km is inclusive and a point one millimetre beyond is ineligible',
    () {
      const origin = geo.LatLng(0, 0);
      final atLimit = origin.destinationPoint(45, storyD75MaxDiameterMetres);
      final beyond = origin.destinationPoint(
        45,
        storyD75MaxDiameterMetres + .001,
      );
      final anchor = _marker(
        'anchor',
        Offset.zero,
        latitude: 0,
        longitude: 0,
        intensity: 4,
      );
      StoryStationMarker member(geo.LatLng point) => _marker(
        'member',
        const Offset(40, 0),
        latitude: point.latitude,
        longitude: point.longitude,
      );
      expect(_distance(anchor, member(atLimit)), storyD75MaxDiameterMetres);
      expect(_distance(anchor, member(beyond)), closeTo(75000.001, 1e-8));
      expect(_d75([anchor, member(atLimit)]).single.count, 2);
      expect(_d75([anchor, member(beyond)]), hasLength(2));
      expect(clusterStoryObservations([anchor, member(beyond)]), hasLength(1));
    },
  );

  test('members within range of the anchor can exceed the pairwise limit', () {
    final anchor = _marker('anchor', const Offset(120, 80), intensity: 4);
    final east = _marker('east', const Offset(135, 80), longitude: 121.5);
    final west = _marker('west', const Offset(105, 80), longitude: 120.5);
    expect(_distance(anchor, east), lessThan(storyD75MaxDiameterMetres));
    expect(_distance(anchor, west), lessThan(storyD75MaxDiameterMetres));
    expect(_distance(east, west), greaterThan(storyD75MaxDiameterMetres));
    expect(_d75([west, east, anchor]).map((c) => c.members), [
      [west],
      [anchor, east],
    ]);
  });

  test(
    'an ineligible nearest cluster yields to an eligible farther cluster',
    () {
      final east = _marker(
        'east',
        const Offset(80, 80),
        longitude: 121.8,
        intensity: 4,
      );
      final west = _marker('west', const Offset(130, 80), intensity: 3);
      final middle = _marker('middle', const Offset(95, 80));
      expect(_d75([middle, west, east]).map((c) => c.members), [
        [west, middle],
        [east],
      ]);
    },
  );

  test(
    'distance wraps longitude and coincident IDs remain separate records',
    () {
      final east = _marker(
        'east',
        const Offset(30, 80),
        longitude: 179.8,
        intensity: 4,
      );
      final west = _marker('west', const Offset(45, 80), longitude: -179.8);
      final duplicate = _marker(
        'west-2',
        const Offset(45, 80),
        longitude: -179.8,
      );
      expect(_d75([duplicate, west, east]).single.members, [
        east,
        west,
        duplicate,
      ]);
      expect(_d75([west]).single.anchor, same(west));
    },
  );

  test('equal eligible screen distances favor canonical anchor order', () {
    final east = _marker(
      'east',
      const Offset(20, 80),
      longitude: 121.2,
      intensity: 4,
    );
    final west = _marker(
      'west',
      const Offset(100, 80),
      longitude: 120.8,
      intensity: 4,
    );
    final middle = _marker('middle', const Offset(60, 80));
    expect(_d75([middle, west, east]).map((c) => c.members), [
      [east, middle],
      [west],
    ]);
  });

  test(
    'coordinate ties use source ID and keep distinct coincident sources',
    () {
      final first = _marker('first', const Offset(10, 10), intensity: 5);
      final last = _marker('last', const Offset(10, 10), intensity: 5);
      final stronger = _marker('stronger', const Offset(55, 10), intensity: 6);
      final y = _marker('north', const Offset(55, 55), latitude: 24);
      final z = _marker('south', const Offset(55, 100));
      for (final markers in [
        [last, first, stronger, z, y],
        [y, z, stronger, first, last],
      ]) {
        final clusters = clusterStoryObservations(markers);
        expect(clusters.map((c) => c.anchor), [y, z, first, stronger]);
        expect(clusters[2].members, [first, last]);
      }
    },
  );

  test('equidistant observation at the inclusive 40 px radius joins the priority anchor', () {
    final west = _marker('west', const Offset(20, 80), intensity: 5);
    final east = _marker(
      'east',
      const Offset(100, 80),
      longitude: 122,
      intensity: 5,
    );
    final mid = _marker('mid', const Offset(60, 80));
    final outside = _marker('outside', const Offset(60, 81));
    final nonfinite = _marker('invalid', const Offset(double.nan, 0));
    for (final markers in [
      [outside, west, mid, east, nonfinite],
      [east, mid, west, nonfinite, outside],
    ]) {
      final clusters = clusterStoryObservations(markers);
      expect(clusters.map((c) => c.anchor), [outside, east, west]);
      expect(clusters[1].members, [east, mid]);
      expect(clusters[2].members, [west]);
    }
    expect(clusterStoryObservations([]), isEmpty);
  });
}

List<StoryMarkerCluster> _d75(List<StoryStationMarker> markers) =>
    clusterStoryObservations(
      markers,
      maxDiameterMetres: storyD75MaxDiameterMetres,
    );

double _distance(StoryStationMarker a, StoryStationMarker b) => geo.LatLng(
  a.latitude,
  a.longitude,
).distanceTo(geo.LatLng(b.latitude, b.longitude));

EarthquakeReport _loadReport(String node, String id) =>
    EarthquakeReport.fromJson(
      jsonDecode(File('$_fixtureDir/$node-$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

EarthquakeReport _reorder(
  EarthquakeReport report,
  void Function<T>(List<T>) reorder,
) {
  List<T> reordered<T>(Iterable<T> entries) {
    final items = entries.toList();
    reorder(items);
    return items;
  }

  return report.copyWith(
    list: {
      for (final area in reordered(report.list.entries))
        area.key: area.value.copyWith(
          town: Map.fromEntries(reordered(area.value.town.entries)),
        ),
    },
  );
}

({LatLng target, double zoom}) _camera(EarthquakeReport report) {
  final bounds = boundsFromPoints([
    LatLng(report.latitude, report.longitude),
    for (final area in report.list.values)
      for (final station in area.town.values)
        LatLng(station.latitude, station.longitude),
  ])!;
  return boundsFitCamera(
    safeFitBounds(bounds)!,
    viewport: StoryMapSnapshot.canvas,
    topInset: 80,
    bottomInset: 260,
    padding: 12,
    minZoom: 2,
    maxZoom: 7,
  )!;
}

// A fixed Mercator reference for mock native responses. Production uses the
// points returned by the snapshot channel.
Offset _project(double lat, double lon, ({LatLng target, double zoom}) camera) {
  double mercatorY(double latitude) {
    final sine = math.sin(latitude * math.pi / 180);
    return 0.5 - math.log((1 + sine) / (1 - sine)) / (4 * math.pi);
  }

  final world = 512 * math.pow(2, camera.zoom);
  return Offset(
    180 + (lon - camera.target.longitude) * world / 360,
    320 + (mercatorY(lat) - mercatorY(camera.target.latitude)) * world,
  );
}

Uint8List _pngHeader() =>
    (ByteData(24)
          ..setUint32(0, 0x89504E47)
          ..setUint32(4, 0x0D0A1A0A)
          ..setUint32(8, 13)
          ..setUint32(12, 0x49484452)
          ..setUint32(16, 720)
          ..setUint32(20, 1280))
        .buffer
        .asUint8List();

StoryStationMarker _marker(
  String id,
  Offset position, {
  double longitude = 121,
  double latitude = 23,
  int intensity = 1,
}) => StoryStationMarker(
  sourceId: id,
  latitude: latitude,
  longitude: longitude,
  position: position,
  intensity: intensity,
);
