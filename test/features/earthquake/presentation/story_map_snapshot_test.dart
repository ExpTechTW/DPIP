import 'dart:async';

import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('com.exptech.dpip/map_snapshot');
const _report = EarthquakeReport(
  id: '115074-2026-1030-043743',
  longitude: 121.82,
  latitude: 24.18,
  location: '',
  depth: 24.7,
  magnitude: 4.5,
  time: 1793306263000,
  trem: 0,
  list: {
    '宜蘭縣': AreaIntensity(
      intensity: 3,
      town: {
        '同名測站': StationIntensity(
          longitude: 121.75,
          latitude: 24.43,
          intensity: 3,
        ),
      },
    ),
    '花蓮縣': AreaIntensity(
      intensity: 1,
      town: {
        '同名測站': StationIntensity(
          longitude: 121.56,
          latitude: 23.79,
          intensity: 1,
        ),
        '另一測站': StationIntensity(
          longitude: 121.56,
          latitude: 23.79,
          intensity: 1,
        ),
      },
    ),
  },
);
const _yilanId = '["宜蘭縣","同名測站"]';
const _hualienId = '["花蓮縣","同名測站"]';
const _otherId = '["花蓮縣","另一測站"]';

Future<StoryMapSnapshot> _capture({
  double scale = 2,
  double zoom = 7,
  EarthquakeReport report = _report,
}) => StoryMapSnapshot.capture(
  report: report,
  style: '{}',
  centerLatitude: 23.84,
  centerLongitude: 121.51,
  zoom: zoom,
  pixelRatio: scale,
);

Map<String, Object> _response(int scale, {double x = 225.6}) {
  final header = ByteData(24)
    ..setUint32(0, 0x89504E47)
    ..setUint32(4, 0x0D0A1A0A)
    ..setUint32(8, 13)
    ..setUint32(12, 0x49484452)
    ..setUint32(16, 360 * scale)
    ..setUint32(20, 640 * scale);
  return {
    'png': header.buffer.asUint8List(),
    'pngWidth': 360 * scale,
    'pngHeight': 640 * scale,
    'logicalWidth': 360.0,
    'logicalHeight': 640.0,
    'points': {
      _otherId: [-10.3, 334.5],
      _hualienId: [-10.3, 334.5],
      'epicenter': [x, 243.2],
      _yilanId: [201.1, 52.9],
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  for (final scale in [1, 2, 3]) {
    test('preserves logical anchors and validates the $scale× PNG', () async {
      messenger.setMockMethodCallHandler(_channel, (call) async {
        expect(call.method, 'captureWithProjection');
        expect(call.arguments, {
          'style': '{}',
          'latitude': 23.84,
          'longitude': 121.51,
          'zoom': 7.0,
          'width': 360.0,
          'height': 640.0,
          'pixelRatio': scale.toDouble(),
          'showLogo': false,
          'points': [
            {'id': 'epicenter', 'latitude': 24.18, 'longitude': 121.82},
            {'id': _yilanId, 'latitude': 24.43, 'longitude': 121.75},
            {'id': _hualienId, 'latitude': 23.79, 'longitude': 121.56},
            {'id': _otherId, 'latitude': 23.79, 'longitude': 121.56},
          ],
        });
        return _response(scale);
      });
      final result = await _capture(scale: scale.toDouble());
      expect(result.epicenter, const Offset(225.6, 243.2));
      expect(result.markers.map((m) => m.sourceId), [
        _yilanId,
        _hualienId,
        _otherId,
      ]);
      expect(result.markers.map((m) => (m.latitude, m.longitude)), [
        (24.43, 121.75),
        (23.79, 121.56),
        (23.79, 121.56),
      ]);
      expect(result.markers.map((m) => m.position), [
        const Offset(201.1, 52.9),
        const Offset(-10.3, 334.5),
        const Offset(-10.3, 334.5),
      ]);
      expect(result.markers.map((m) => m.intensity), [3, 1, 1]);
    });
  }

  test(
    'rejects missing, mismatched and non-finite projection metadata',
    () async {
      final valid = _response(2);
      final points = valid['points']! as Map;
      for (final response in [
        null,
        {...valid}..remove('points'),
        {
          ...valid,
          'points': {...points}..remove(_yilanId),
        },
        {
          ...valid,
          'points': {...points}..[_yilanId] = [double.nan, 5],
        },
        {
          ...valid,
          'points': {...points}..[_yilanId] = ['3', 5],
        },
        {
          ...valid,
          'points': {
            ...points,
            'unknown': [1, 2],
          }..remove(_yilanId),
        },
        {...valid, 'logicalWidth': 640.0},
        {...valid, 'pngWidth': 360},
        {...valid, 'png': _response(1)['png']},
        {...valid, 'png': Uint8List(24)},
      ]) {
        messenger.setMockMethodCallHandler(_channel, (_) async => response);
        await expectLater(_capture(), throwsFormatException);
      }
    },
  );

  test('propagates native failures and missing methods', () async {
    for (final code in ['bad_args', 'snapshot_failed', 'no_image']) {
      messenger.setMockMethodCallHandler(_channel, (_) async {
        throw PlatformException(code: code);
      });
      await expectLater(
        _capture(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', code)),
      );
    }
    messenger.setMockMethodCallHandler(_channel, null);
    await expectLater(_capture(), throwsA(isA<MissingPluginException>()));
  });

  test(
    'projects every valid source and excludes invalid coordinates',
    () async {
      final report = _report.copyWith(
        list: {
          ..._report.list,
          'invalid': const AreaIntensity(
            intensity: 9,
            town: {
              'latitude': StationIntensity(
                longitude: 121,
                latitude: 91,
                intensity: 9,
              ),
              'longitude': StationIntensity(
                longitude: double.infinity,
                latitude: 24,
                intensity: 9,
              ),
            },
          ),
        },
      );
      var calls = 0;
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls++;
        expect(call.arguments['points'], hasLength(4));
        return _response(2);
      });
      final result = await _capture(report: report);
      expect(result.markers.map((marker) => marker.sourceId), [
        _yilanId,
        _hualienId,
        _otherId,
      ]);
      await expectLater(
        _capture(report: report.copyWith(longitude: 181)),
        throwsFormatException,
      );
      expect(calls, 1);
    },
  );

  test('supports an epicenter with no valid observations', () async {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      expect(call.arguments['points'], hasLength(1));
      return {
        ..._response(2),
        'points': {
          'epicenter': [180.0, 227.0],
        },
      };
    });
    final result = await _capture(report: _report.copyWith(list: {}));
    expect(result.markers, isEmpty);
    expect(result.epicenter, const Offset(180, 227));
  });

  test(
    'keeps concurrent responses paired when they finish out of order',
    () async {
      final older = Completer<Map<String, Object>>();
      final newer = Completer<Map<String, Object>>();
      messenger.setMockMethodCallHandler(
        _channel,
        (call) => call.arguments['zoom'] == 7.0 ? older.future : newer.future,
      );
      final first = _capture(zoom: 7, scale: 1);
      final second = _capture(zoom: 8, scale: 3);
      newer.complete(_response(3, x: 190));
      final latest = await second;
      older.complete(_response(1, x: 221));
      final previous = await first;
      expect(latest.epicenter.dx, 190);
      expect(ByteData.sublistView(latest.png).getUint32(16), 1080);
      expect(previous.epicenter.dx, 221);
      expect(ByteData.sublistView(previous.png).getUint32(16), 360);
    },
  );
}
