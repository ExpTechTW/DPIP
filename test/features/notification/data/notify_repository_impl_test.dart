/// [NotifyRepositoryImpl]'s contract has two parts: every transport/decode
/// fault folds into a typed [Failure] (never a raw `DioException`, and never a
/// [NotifySettings.fromWire] length mismatch escaping as a bare
/// `FormatException`), and a 401 — the shape of "this push token has never
/// registered a location" — is recovered exactly once before giving up.
///
/// The recovery has three ways to end, and swapping any two of them is
/// invisible until a real 401 hits it in the field:
/// - no fix, or the registration request itself fails: the *original* 401
///   surfaces, never the registration's own error;
/// - registration succeeds and the retry succeeds: `Ok` with the retried
///   settings;
/// - registration succeeds but the retry itself fails: the *retry's* failure
///   surfaces, not the original 401.
///
/// It also waits out a real two-second cool-down before each of the two
/// requests the recovery path makes — skip that and the retry 429s just as
/// reliably as an immediate registration does — so those cases run under
/// [fakeAsync] rather than as a real two-to-four-second test.
///
/// One fixed fact of this host, not this file: `dart:io`'s `Platform.isIOS` is
/// false on any machine that runs `flutter test` (it is never actually an iOS
/// device), so the registration call's `platform` argument is deterministically
/// `0` below regardless of what machine runs the suite.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:dpip/features/notification/data/notify_repository_impl.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Every dataset answers with the same fault, for the non-401 fault matrix
/// shared by [fetch] and [setChannel].
class _FailingNotifyApi extends NotifyApi {
  _FailingNotifyApi(this.error)
    : super(ApiClient(Dio(), RegionSelection(SettingsStore.inMemory({}))));

  final Object error;

  @override
  Future<List<dynamic>> getNotify(String token) async => throw error;

  @override
  Future<List<dynamic>> setNotify(
    String token,
    int channel,
    int status,
  ) async => throw error;
}

/// Succeeds with a fixed wire list and records every call's arguments — the
/// happy path, and the base for the repository's own decode failure below.
class _OkNotifyApi extends NotifyApi {
  _OkNotifyApi(this.wire)
    : super(ApiClient(Dio(), RegionSelection(SettingsStore.inMemory({}))));

  final List<dynamic> wire;
  final List<String> getCalls = [];
  final List<(String token, int channel, int status)> setCalls = [];

  @override
  Future<List<dynamic>> getNotify(String token) async {
    getCalls.add(token);
    return wire;
  }

  @override
  Future<List<dynamic>> setNotify(String token, int channel, int status) async {
    setCalls.add((token, channel, status));
    return wire;
  }
}

/// Answers [getNotify] from a fixed queue — one entry per call, a
/// [DioException] to throw or a wire list to return — so a 401 followed by a
/// retry can be scripted without a mocking framework. [setNotify] is never
/// exercised by the 401-recovery scenarios this fake serves, so it throws
/// loudly instead of silently reaching the real `ApiClient` given to `super`.
class _ScriptedNotifyApi extends NotifyApi {
  _ScriptedNotifyApi(this._answers)
    : super(ApiClient(Dio(), RegionSelection(SettingsStore.inMemory({}))));

  final List<Object> _answers;
  int calls = 0;

  @override
  Future<List<dynamic>> getNotify(String token) async {
    final answer = _answers[calls];
    calls++;
    if (answer is Exception || answer is Error) throw answer;
    return answer as List<dynamic>;
  }

  @override
  Future<List<dynamic>> setNotify(
    String token,
    int channel,
    int status,
  ) async => throw UnimplementedError();
}

/// Records the location-registration call; [error] makes the request itself
/// fail the way a rate-limited backend would.
class _FakeLocationApi extends LocationApi {
  _FakeLocationApi({this.error})
    : super(ApiClient(Dio(), RegionSelection(SettingsStore.inMemory({}))));

  final Object? error;
  int calls = 0;
  ({int platform, String token, String version, double lat, double lng})?
  lastArgs;

  @override
  Future<dynamic> updateDeviceLocation({
    required int platform,
    required String token,
    required String version,
    required double lat,
    required double lng,
  }) async {
    calls++;
    lastArgs = (
      platform: platform,
      token: token,
      version: version,
      lat: lat,
      lng: lng,
    );
    final err = error;
    if (err != null) throw err;
    return <String, dynamic>{};
  }
}

/// A [LocationService] whose GPS availability is always true and whose fix is
/// exactly [fix] — `null` reproduces "no position available" without needing a
/// hand-written fake class, since [LocationService.currentFix] only ever calls
/// its injected `isAvailable`/`fix` seams.
LocationService _locationServiceWithFix(GpsFix? fix) => LocationService(
  const TownDirectory({}),
  isAvailable: () async => true,
  fix: () async => fix,
);

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v2/notify/token');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

/// [fetch] and [setChannel] share one fault path, so one loop holds both to
/// the same contract instead of two near-identical tests.
final Map<String, Future<Result<NotifySettings>> Function(NotifyRepository)>
_calls = {
  'fetch': (repo) => repo.fetch('tok'),
  'setChannel': (repo) => repo.setChannel('tok', NotifyChannel.eew, 1),
};

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = NotifyRepositoryImpl(
    _FailingNotifyApi(error),
    _FakeLocationApi(),
    _locationServiceWithFix(null),
  );

  for (final entry in _calls.entries) {
    final result = await entry.value(repo);
    expect(result.failureOrNull, failure, reason: entry.key);
    expect(result.valueOrNull, isNull, reason: entry.key);
  }
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'DPIP',
      packageName: 'com.exptech.dpip',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('a 404 folds into NotFoundFailure, not a crash', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.badResponse, status: 404),
      isA<NotFoundFailure>(),
    );
  });

  test('a timeout folds into TimeoutFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionTimeout),
      isA<TimeoutFailure>(),
    );
  });

  test('a dropped connection folds into NetworkFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionError),
      isA<NetworkFailure>(),
    );
  });

  test('malformed JSON folds into DecodeFailure', () async {
    await _expectEveryCallFailsWith(
      const FormatException('unexpected token'),
      isA<DecodeFailure>(),
    );
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      await _expectEveryCallFailsWith(
        StateError('boom'),
        isA<UnexpectedFailure>(),
      );
    },
  );

  test('a non-401 server error never attempts location recovery', () async {
    final locationApi = _FakeLocationApi();
    final repo = NotifyRepositoryImpl(
      _FailingNotifyApi(_dio(DioExceptionType.badResponse, status: 503)),
      locationApi,
      _locationServiceWithFix((lat: 24.1, lng: 120.7)),
    );

    final result = await repo.fetch('tok');

    expect(
      result.failureOrNull,
      isA<NetworkFailure>().having(
        (f) => f.message,
        'message',
        contains('503'),
      ),
    );
    expect(locationApi.calls, 0);
  });

  test(
    'fetch maps a full wire list into NotifySettings and threads the token',
    () async {
      final api = _OkNotifyApi(const [2, 1, 0, 2, 1, 0, 1, 1, 0]);
      final repo = NotifyRepositoryImpl(
        api,
        _FakeLocationApi(),
        _locationServiceWithFix(null),
      );

      final result = await repo.fetch('push-token');

      final settings = result.valueOrNull;
      expect(settings, isNotNull);
      expect(settings!.optionOf(NotifyChannel.eew), 2);
      expect(settings.optionOf(NotifyChannel.announcement), 0);
      expect(api.getCalls, ['push-token']);
    },
  );

  test(
    'setChannel sends the channel index and option, and maps the echoed list',
    () async {
      final api = _OkNotifyApi(const [0, 0, 0, 0, 0, 0, 0, 0, 0]);
      final repo = NotifyRepositoryImpl(
        api,
        _FakeLocationApi(),
        _locationServiceWithFix(null),
      );

      final result = await repo.setChannel(
        'push-token',
        NotifyChannel.tsunami,
        1,
      );

      expect(result.valueOrNull, isNotNull);
      expect(api.setCalls, [('push-token', NotifyChannel.tsunami.index, 1)]);
    },
  );

  test(
    "a wire list of the wrong length is the repository's own decode failure",
    () async {
      // Nine channels exist; this echoes only three — a shape only the
      // repository's own `NotifySettings.fromWire` call can catch, since the
      // API layer above successfully decoded and returned this list as-is.
      final api = _OkNotifyApi(const [1, 2, 3]);
      final repo = NotifyRepositoryImpl(
        api,
        _FakeLocationApi(),
        _locationServiceWithFix(null),
      );

      final result = await repo.fetch('push-token');

      expect(result.failureOrNull, isA<DecodeFailure>());
    },
  );

  test('a 401 with no fix available surfaces the original failure', () {
    fakeAsync((async) {
      final api = _ScriptedNotifyApi([
        _dio(DioExceptionType.badResponse, status: 401),
      ]);
      final locationApi = _FakeLocationApi();
      final repo = NotifyRepositoryImpl(
        api,
        locationApi,
        _locationServiceWithFix(null),
      );

      Result<NotifySettings>? result;
      unawaited(repo.fetch('push-token').then((r) => result = r));
      async.flushMicrotasks();
      // Still waiting out the pre-registration cool-down — proves the
      // recovery genuinely delays rather than resolving inline.
      expect(result, isNull);

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();

      expect(
        result?.failureOrNull,
        isA<NetworkFailure>().having(
          (f) => f.message,
          'message',
          contains('401'),
        ),
      );
      expect(locationApi.calls, 0);
      expect(api.calls, 1);
    });
  });

  test(
    'a 401 whose registration request itself fails surfaces the original 401',
    () {
      fakeAsync((async) {
        final api = _ScriptedNotifyApi([
          _dio(DioExceptionType.badResponse, status: 401),
        ]);
        final locationApi = _FakeLocationApi(
          error: _dio(DioExceptionType.badResponse, status: 429),
        );
        final repo = NotifyRepositoryImpl(
          api,
          locationApi,
          _locationServiceWithFix((lat: 24.1, lng: 120.7)),
        );

        Result<NotifySettings>? result;
        unawaited(repo.fetch('push-token').then((r) => result = r));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(
          result?.failureOrNull,
          isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            contains('401'),
          ),
        );
        expect(locationApi.calls, 1);
        // No second cool-down, no retry: registration failing is terminal.
        expect(api.calls, 1);
      });
    },
  );

  test('a 401 with a fix registers the location and retries to success', () {
    fakeAsync((async) {
      final api = _ScriptedNotifyApi([
        _dio(DioExceptionType.badResponse, status: 401),
        const [2, 1, 0, 2, 1, 0, 1, 1, 0],
      ]);
      final locationApi = _FakeLocationApi();
      final repo = NotifyRepositoryImpl(
        api,
        locationApi,
        _locationServiceWithFix((lat: 24.1, lng: 120.7)),
      );

      Result<NotifySettings>? result;
      unawaited(repo.fetch('push-token').then((r) => result = r));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2)); // pre-registration cool-down
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2)); // pre-retry cool-down
      async.flushMicrotasks();

      expect(result?.valueOrNull?.optionOf(NotifyChannel.eew), 2);
      expect(locationApi.calls, 1);
      expect(locationApi.lastArgs, (
        platform: 0,
        token: 'push-token',
        version: '9.9.9',
        lat: 24.1,
        lng: 120.7,
      ));
      expect(api.calls, 2);
    });
  });

  test(
    "a 401 with a fix surfaces the retry's own failure, not the original 401",
    () {
      fakeAsync((async) {
        final api = _ScriptedNotifyApi([
          _dio(DioExceptionType.badResponse, status: 401),
          _dio(DioExceptionType.badResponse, status: 429),
        ]);
        final locationApi = _FakeLocationApi();
        final repo = NotifyRepositoryImpl(
          api,
          locationApi,
          _locationServiceWithFix((lat: 24.1, lng: 120.7)),
        );

        Result<NotifySettings>? result;
        unawaited(repo.fetch('push-token').then((r) => result = r));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(
          result?.failureOrNull,
          isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            contains('429'),
          ),
        );
        expect(locationApi.calls, 1);
        expect(api.calls, 2);
      });
    },
  );
}
