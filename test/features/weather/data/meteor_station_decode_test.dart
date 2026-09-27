/// The two decode helpers every meteor repository (weather / rain / lightning)
/// shares: the station directory and the delta-seconds history axis. Neither
/// is a class, so nothing but discipline routes them through `guardResult` —
/// a version that forgot the wrapper would turn a 404 into an uncaught
/// exception instead of a typed [Failure], and `fetchStations`' own
/// `as Map<String, dynamic>` cast would crash the app on one malformed
/// directory entry instead of reporting [DecodeFailure]. Each repository's own
/// test only proves it *calls* these; this is the one place that proves they
/// behave correctly on their own.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/weather/data/meteor_station_decode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fetchStations', () {
    test('decodes the raw station map, keyed and typed', () async {
      final result = await fetchStations(
        () async => {
          'C0A940': {
            'n': 'Taipei',
            'c': 'Taipei City',
            't': 'Zhongzheng',
            'alt': 5.0,
            'lat': 25.033,
            'lon': 121.5654,
          },
          'C0A950': {
            'n': 'Banqiao',
            'c': 'New Taipei City',
            't': 'Banqiao',
            'alt': 9.0,
            'lat': 25.014,
            'lon': 121.4627,
          },
        },
      );

      final stations = result.valueOrNull;
      expect(stations?.keys, {'C0A940', 'C0A950'});
      expect(stations?['C0A940']?.name, 'Taipei');
      expect(stations?['C0A940']?.altitude, 5.0);
      expect(stations?['C0A950']?.county, 'New Taipei City');
    });

    test('a fetch fault folds into the mapped Failure', () async {
      final options = RequestOptions(path: '/api/v5/meteor/weather/station');
      final result = await fetchStations(
        () async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test(
      'a malformed station entry folds into DecodeFailure, not a crash',
      () async {
        final result = await fetchStations(
          () async => {'C0A940': 'not a station object'},
        );

        expect(result.failureOrNull, isA<DecodeFailure>());
      },
    );
  });

  group('fetchHistory', () {
    test('restores the delta axis to absolute seconds', () async {
      final result = await fetchHistory(() async => [1000, 5, 5, 0]);

      expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
    });

    test('an empty history is Ok with an empty list, not a failure', () async {
      final result = await fetchHistory(() async => []);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('a fetch fault folds into the mapped Failure', () async {
      final options = RequestOptions(path: '/api/v5/meteor/weather/list');
      final result = await fetchHistory(
        () async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(result.failureOrNull, isA<TimeoutFailure>());
    });
  });
}
