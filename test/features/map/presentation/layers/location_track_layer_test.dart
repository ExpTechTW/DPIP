/// The track layer reads a file only this phone has. These pin what it draws
/// for each window, that a refresh and a clear reach the map, and that the
/// camera is fitted on a deliberate choice and never on a background refresh.
library;

import 'dart:async';
import 'dart:io';

import 'package:dpip/core/geo/location_track.dart';
import 'package:dpip/core/geo/track_digest.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/features/map/presentation/layers/location_track_layer.dart';
import 'package:dpip/shared/map/map_layer_category.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../../core/geo/location_track_fixture.dart';
import '../../raster_timeline_harness.dart';

class _Map extends RecordingMapController {
  final List<List<dynamic>> cameras = [];

  @override
  Future<bool?> animateCamera(
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async {
    cameras.add(cameraUpdate.toJson() as List<dynamic>);
    return true;
  }
}

/// 2026-10-16 03:00 UTC — 11:00 in Taipei.
final _now = DateTime.utc(2026, 10, 16, 3);

int _secondsAgo(Duration ago) =>
    _now.subtract(ago).millisecondsSinceEpoch ~/ 1000;

/// A short walk of [count] fixes a minute apart, starting [ago] before now.
List<(int, double, double)> _walk(
  Duration ago, {
  int count = 10,
  double lat = 25.0330,
}) => [
  for (var i = 0; i < count; i++)
    (_secondsAgo(ago) + i * 60, lat + i * 0.0003, 121.5654 + i * 0.0002),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String path;
  late _Map map;
  late List<String> channelCalls;
  late BackgroundLocationService service;
  const channel = MethodChannel('test/background_location');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('location_track_layer_test');
    path = '${dir.path}/location_track.db';
    map = _Map();
    channelCalls = [];
    service = BackgroundLocationService(
      platform: 0,
      version: 'test',
      channel: channel,
    );
    // What the native side does on `clearTrack`: empty the table through its
    // own handle, then answer.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          channelCalls.add(call.method);
          if (call.method == 'clearTrack') {
            final db = sqlite3.sqlite3.open(path);
            db.execute('DELETE FROM fix');
            db.close();
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    dir.deleteSync(recursive: true);
  });

  LocationTrackMapLayer makeLayer() => LocationTrackMapLayer(
    service,
    open: () async => LocationTrack.at(path),
    now: () => _now,
  );

  List<Map<String, dynamic>> features() => [
    for (final feature
        in (map.sourceData['location-track-src']?['features'] as List?) ??
            const [])
      Map<String, dynamic>.from(feature as Map),
  ];

  Iterable<Map<String, dynamic>> ofKind(String kind) => features().where(
    (feature) => (feature['properties'] as Map)['kind'] == kind,
  );

  test('the layer is filed under daily life', () {
    expect(LocationTrackMapLayer.layerId, 'location-track');
    expect(categoryOf(LocationTrackMapLayer.layerId), MapLayerCategory.life);
  });

  group('trackRangeStart', () {
    test('today is the Taipei calendar day', () {
      // 11:00 in Taipei → midnight Taipei is 16:00 UTC the day before.
      expect(
        trackRangeStart(TrackRange.today, _now),
        DateTime.utc(2026, 10, 15, 16),
      );
      // 00:30 Taipei on the 16th is still the 16th, though UTC says the 15th.
      expect(
        trackRangeStart(TrackRange.today, DateTime.utc(2026, 10, 15, 16, 30)),
        DateTime.utc(2026, 10, 15, 16),
      );
    });

    test('the rolling windows and all', () {
      expect(
        trackRangeStart(TrackRange.week, _now),
        _now.subtract(const Duration(days: 7)),
      );
      expect(
        trackRangeStart(TrackRange.month, _now),
        _now.subtract(const Duration(days: 30)),
      );
      expect(
        trackRangeStart(TrackRange.all, _now).isBefore(DateTime.utc(1971)),
        isTrue,
      );
    });
  });

  test('no file is the empty state, and an empty map', () async {
    final layer = makeLayer();
    await layer.render(map);
    await layer.pending;
    expect(layer.snapshot.value!.recorded, isFalse);
    expect(map.calls, contains('addLineLayer:location-track-line'));
    expect(features(), isEmpty);
    await layer.clear(map);
  });

  test('each window draws only its own fixes, seven days by default', () async {
    writeTrackFixture(path, [
      ..._walk(const Duration(days: 40)),
      ..._walk(const Duration(days: 20), lat: 24.5),
      ..._walk(const Duration(days: 3), lat: 24.0),
      ..._walk(const Duration(hours: 2), lat: 23.5),
    ]);
    final layer = makeLayer();
    await layer.render(map);
    await layer.pending;

    LocationTrackSnapshot snapshot() => layer.snapshot.value!;
    expect(layer.range.value, TrackRange.week);
    expect(snapshot().recorded, isTrue);
    expect(snapshot().fixes, 40, reason: 'stats count the whole file');
    expect(snapshot().digest.fixes, 20);

    await layer.selectRange(TrackRange.today);
    expect(snapshot().digest.fixes, 10);
    await layer.selectRange(TrackRange.month);
    expect(snapshot().digest.fixes, 30);
    await layer.selectRange(TrackRange.all);
    expect(snapshot().digest.fixes, 40);
    expect(
      snapshot().oldest!.millisecondsSinceEpoch ~/ 1000,
      _secondsAgo(const Duration(days: 40)),
    );

    // The newest fix is the marker, exactly where it was recorded.
    final latest = ofKind('latest').single;
    final coordinates = (latest['geometry'] as Map)['coordinates'] as List;
    expect(coordinates[1], closeTo(23.5 + 9 * 0.0003, 1e-9));
    // Four separate outings, each more than two hours from the next: four
    // runs of nine strokes, and nothing joining them.
    final strokes = ofKind('line').fold<int>(
      0,
      (sum, feature) =>
          sum + ((feature['geometry'] as Map)['coordinates'] as List).length,
    );
    expect(strokes, 36);
    await layer.clear(map);
  });

  test('the camera fits a deliberate choice, not a refresh', () async {
    writeTrackFixture(path, _walk(const Duration(hours: 3)));
    final layer = makeLayer()
      ..rememberFrameMetrics(
        viewport: const Size(400, 800),
        topInset: 24,
        bottomInset: 200,
      );
    await layer.render(map);
    await layer.pending;
    expect(map.cameras, hasLength(1));
    expect(map.cameras.single.first, 'newLatLngZoom');
    final zoom = map.cameras.single.last as double;
    expect(zoom, lessThanOrEqualTo(15));

    // New fixes arrive while the app is in the background.
    layer.onSurfaceVisibility(false);
    writeTrackFixture(path, _walk(const Duration(minutes: 30), count: 5));
    layer.onSurfaceVisibility(true);
    await layer.pending;
    expect(layer.snapshot.value!.digest.fixes, 15);
    expect(map.cameras, hasLength(1), reason: 'a refresh moved the camera');

    await layer.selectRange(TrackRange.today);
    expect(map.cameras, hasLength(2));
    await layer.clear(map);
  });

  test(
    'coming back to the foreground re-reads only when the file changed',
    () async {
      writeTrackFixture(path, _walk(const Duration(hours: 3)));
      final layer = makeLayer();
      await layer.render(map);
      await layer.pending;
      final uploads = map.calls
          .where((call) => call == 'setGeoJsonSource:location-track-src')
          .length;

      layer
        ..onSurfaceVisibility(false)
        ..onSurfaceVisibility(true);
      await layer.pending;
      expect(
        map.calls.where(
          (call) => call == 'setGeoJsonSource:location-track-src',
        ),
        hasLength(uploads),
        reason: 'nothing changed, so nothing is redrawn',
      );

      layer.onSurfaceVisibility(false);
      writeTrackFixture(path, _walk(const Duration(minutes: 10), count: 3));
      layer.onSurfaceVisibility(true);
      await layer.pending;
      expect(layer.snapshot.value!.digest.fixes, 13);
      expect(
        map.calls.where(
          (call) => call == 'setGeoJsonSource:location-track-src',
        ),
        hasLength(uploads + 1),
      );
      await layer.clear(map);
    },
  );

  test('a file that appears later is picked up on the next refresh', () async {
    final layer = makeLayer();
    await layer.render(map);
    await layer.pending;
    expect(layer.snapshot.value!.recorded, isFalse);

    // Background location was granted while the app was away.
    writeTrackFixture(path, _walk(const Duration(hours: 1)));
    await layer.refresh();
    expect(layer.snapshot.value!.recorded, isTrue);
    expect(ofKind('latest'), hasLength(1));
    await layer.clear(map);
  });

  test('clearing goes through the native side and empties the map', () async {
    writeTrackFixture(path, _walk(const Duration(hours: 1)));
    final layer = makeLayer();
    await layer.render(map);
    await layer.pending;
    expect(features(), isNotEmpty);

    expect(await layer.clearTrack(), isTrue);
    expect(channelCalls, ['clearTrack']);
    expect(layer.snapshot.value!.recorded, isFalse);
    expect(features(), isEmpty);
    expect(layer.busy.value, isFalse);
    await layer.clear(map);
  });

  test('a clear the native side did not perform is not reported', () async {
    writeTrackFixture(path, _walk(const Duration(hours: 1)));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          channelCalls.add(call.method);
          throw PlatformException(code: 'io', message: 'disk');
        });
    final layer = makeLayer();
    await layer.render(map);
    await layer.pending;

    expect(await layer.clearTrack(), isFalse);
    expect(channelCalls, ['clearTrack']);
    expect(layer.snapshot.value!.recorded, isTrue);
    expect(features(), isNotEmpty);
    await layer.clear(map);
  });

  test('a load superseded by a newer one never lands', () async {
    writeTrackFixture(path, [
      ..._walk(const Duration(days: 20)),
      ..._walk(const Duration(hours: 1)),
    ]);
    final entered = Completer<void>();
    final gate = Completer<void>();
    var reads = 0;
    final layer = LocationTrackMapLayer(
      service,
      open: () async => LocationTrack.at(path),
      now: () => _now,
      digest: (track, from) async {
        // Hold the "today" read (the second) until the month read has drawn.
        if (reads++ == 1) {
          entered.complete();
          await gate.future;
        }
        return TrackDigest.read(track, from);
      },
    );
    await layer.render(map);
    await layer.pending;
    final slow = layer.selectRange(TrackRange.today);
    await entered.future;
    await layer.selectRange(TrackRange.month);
    gate.complete();
    await slow;
    expect(layer.range.value, TrackRange.month);
    expect(layer.snapshot.value!.digest.fixes, 20);
    await layer.clear(map);
  });

  group('trackGeoJson', () {
    TrackDigest digestOf(List<(int, int, int)> fixes) {
      final builder = TrackDigestBuilder();
      for (final (t, lat, lng) in fixes) {
        builder.add(t, lat, lng);
      }
      return builder.build();
    }

    test('groups strokes into at most eight shades of age', () {
      final digest = digestOf([
        for (var i = 0; i < 500; i++) (i * 600, 250000 + i * 5, 1210000),
      ]);
      final json = trackGeoJson(digest);
      final lines = [
        for (final feature in json['features'] as List)
          if ((feature as Map)['properties']['kind'] == 'line') feature,
      ];
      expect(lines.length, lessThanOrEqualTo(8));
      final total = lines.fold<int>(
        0,
        (sum, feature) =>
            sum + ((feature['geometry'] as Map)['coordinates'] as List).length,
      );
      expect(total, digest.segments.length);
      final shades = [
        for (final feature in lines) feature['properties']['r'] as double,
      ];
      expect(shades.every((r) => r > 0 && r < 1), isTrue);
      expect(shades, orderedEquals([...shades]..sort()));
    });

    test('a window with nothing in it draws nothing', () {
      expect(trackGeoJson(TrackDigest.empty)['features'], isEmpty);
      expect(trackGeoJson(null)['features'], isEmpty);
    });

    test('a single fix is only the latest marker', () {
      final json = trackGeoJson(digestOf([(0, 250000, 1210000)]));
      final features = json['features'] as List;
      // The lone fix is both a dot and the marker; the marker draws on top.
      expect(
        features.map((feature) => (feature as Map)['properties']['kind']),
        containsAll(['latest']),
      );
    });
  });
}
