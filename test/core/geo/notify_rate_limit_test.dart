/// The app's requests to the notify backend against a model of its per-IP
/// limiter: one request a second and twenty a minute per address, a refused
/// request not counted (notify-server-go, `IPRateLimiter`).
///
/// Each sender is throttled on its own; what these pin is that, sharing one
/// lane, they cannot make the server refuse one of them, that the location
/// report goes before the Live Activity report — and that a report the server
/// refuses anyway is not lost.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/device_registration.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/network/notify_request_lane.dart';
import 'package:dpip/core/notifications/live_activity_registration.dart';
import 'package:dpip/core/platform/live_activity_tokens.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server's limiter, on the fake clock, behind a network that takes
/// [upload] to deliver a request and [download] to bring the answer back.
class _Server {
  _Server(this.async);

  final FakeAsync async;
  static const upload = Duration(milliseconds: 300);
  static const download = Duration(milliseconds: 100);

  /// Every request that reached the server: what, when, and the answer.
  final arrivals = <({String route, Duration at, int status})>[];
  final _accepted = <Duration>[];

  /// Requests from somebody else on the same address, which this app's lane
  /// knows nothing about.
  void neighbour() => _answer('neighbour');

  Future<void> call(String route) async {
    await Future<void>.delayed(upload);
    final status = _answer(route);
    await Future<void>.delayed(download);
    if (status != 200) {
      final options = RequestOptions(path: '/$route');
      throw DioException(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: status),
        type: DioExceptionType.badResponse,
      );
    }
  }

  int _answer(String route) {
    final now = async.elapsed;
    _accepted.removeWhere((at) => now - at >= const Duration(minutes: 1));
    final tooSoon =
        _accepted.isNotEmpty &&
        now - _accepted.last < const Duration(seconds: 1);
    final status = tooSoon || _accepted.length >= 20 ? 429 : 200;
    if (status == 200) _accepted.add(now);
    arrivals.add((route: route, at: now, status: status));
    return status;
  }

  Iterable<String> get refused =>
      arrivals.where((a) => a.status == 429).map((a) => a.route);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const here = (lat: 25.03, lng: 121.56);
  const there = (lat: 24.15, lng: 120.67);

  test('a registration, a pending location and a settings fetch at once: '
      'no 429', () {
    fakeAsync((async) {
      final server = _Server(async);
      final lane = NotifyRequestLane(elapsed: () => async.elapsed);
      final settings = SettingsStore.inMemory();
      final now = DateTime.utc(2026, 11, 29).add(async.elapsed);

      // A previous run left a fix the server never took.
      final previous = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: settings,
        now: () => now.subtract(const Duration(hours: 1)),
        onMoved: (fix) async => throw StateError('offline'),
      );
      previous.reportNow(there);
      async.flushMicrotasks();
      previous.dispose();

      final sent = <GpsFix>[];
      late final DeviceRegistration registration;
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: settings,
        now: () => now.add(async.elapsed),
        onReported: (_) => registration.recordSuccess(),
        onMoved: (fix) async {
          await lane.run(() => server.call('location'));
          sent.add(fix);
          return true;
        },
      );
      registration = DeviceRegistration(
        settings: settings,
        token: () => 'push-token',
        fix: () async => here,
        report: reporter.reportNow,
        resend: reporter.retryPending,
        lane: lane,
        now: () => now.add(async.elapsed),
      );

      // Launch: everything at the same instant.
      reporter.start();
      registration.ensure('launch');
      lane.run(() => server.call('notify'));
      async.elapse(const Duration(minutes: 5));

      expect(server.refused, isEmpty);
      expect(server.arrivals.map((a) => a.route), contains('notify'));
      // The fix the previous run lost reached the server, and registered the
      // token: the registration had nothing left to send.
      expect(sent, [there]);
      expect(settings.getString(SettingKeys.pendingLocationReport), isNull);
      expect(settings.getString(SettingKeys.registeredTokenHash), isNotNull);
      for (var i = 1; i < server.arrivals.length; i++) {
        expect(
          server.arrivals[i].at - server.arrivals[i - 1].at,
          greaterThanOrEqualTo(const Duration(seconds: 1)),
        );
      }
      reporter.dispose();
    });
  });

  test('a location report a neighbour got refused is sent again', () {
    fakeAsync((async) {
      final server = _Server(async);
      final lane = NotifyRequestLane(elapsed: () => async.elapsed);
      final settings = SettingsStore.inMemory();
      final sent = <GpsFix>[];
      final positions = StreamController<GpsFix>();
      final reporter = DeviceLocationReporter(
        positions: () => positions.stream,
        settings: settings,
        now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
        onMoved: (fix) async {
          await lane.run(() => server.call('location'));
          sent.add(fix);
          return true;
        },
      )..start();

      // Somebody else on the address spends the second the report lands in.
      async.elapse(const Duration(milliseconds: 100));
      server.neighbour();
      positions.add(there);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(server.refused, ['location']);
      expect(sent, isEmpty);
      expect(settings.getString(SettingKeys.pendingLocationReport), isNotNull);

      // Kept, and sent once the cool-down is over.
      async.elapse(const Duration(seconds: 61));
      expect(sent, [there]);
      expect(settings.getString(SettingKeys.pendingLocationReport), isNull);
      reporter.dispose();
      positions.close();
    });
  });

  test('launch more than six hours on, somewhere new: the location report, '
      'then the Live Activity report, and no 429', () {
    fakeAsync((async) {
      final server = _Server(async);
      final lane = NotifyRequestLane(elapsed: () => async.elapsed);
      final launch = DateTime.utc(2026, 11, 29, 12);
      DateTime now() => launch.add(async.elapsed);
      String hash(String value) =>
          sha256.convert(utf8.encode(value)).toString();

      // Registered and reported seven hours ago; the Live Activity triple too.
      final ago = launch.subtract(const Duration(hours: 7));
      final settings = SettingsStore.inMemory({
        SettingKeys.registeredTokenHash.name: hash('push-token'),
        SettingKeys.deviceReportedAtMs.name: ago.millisecondsSinceEpoch,
        SettingKeys.deviceLocationUpdatedAtMs.name: ago.millisecondsSinceEpoch,
        SettingKeys.liveActivityReportedHash.name: hash(
          'push-token\npts-token\ntrue',
        ),
        SettingKeys.liveActivityReportedAtMs.name: ago.millisecondsSinceEpoch,
      });

      final positions = StreamController<GpsFix>();
      late final DeviceRegistration registration;
      final reporter = DeviceLocationReporter(
        positions: () => positions.stream,
        settings: settings,
        now: now,
        calibratedNow: now,
        onReported: (_) => registration.recordSuccess(),
        onMoved: (fix) async {
          await lane.run(() => server.call('location'));
          return true;
        },
      );
      registration = DeviceRegistration(
        settings: settings,
        token: () => 'push-token',
        fix: () async => there,
        report: reporter.reportNow,
        resend: reporter.retryPending,
        lane: lane,
        now: now,
      );
      final liveActivity = LiveActivityRegistration(
        settings: settings,
        token: () => 'push-token',
        registered: () => registration.registered,
        states: Stream<LiveActivityState>.value((
          token: 'pts-token',
          enabled: true,
        )),
        report: (token, pushToStart, enabled) => lane.run(
          () => server.call('liveactivity'),
          priority: NotifyRequestPriority.deferred,
        ),
        now: now,
      );

      // What the services host does: the launch's location work under a hold,
      // then the Live Activity, whose first state arrives at once.
      lane.holdDeferred(() async {
        reporter.start();
        // The first fix takes a while; it is somewhere new.
        await Future<void>.delayed(const Duration(seconds: 3));
        positions.add(there);
        await Future<void>.delayed(Duration.zero);
        registration.ensure('launch');
        liveActivity.ensure('launch');
      });
      liveActivity.start();
      async.elapse(const Duration(minutes: 5));

      expect(server.refused, isEmpty);
      expect(server.arrivals.map((a) => a.route), ['location', 'liveactivity']);
      expect(
        server.arrivals[1].at - server.arrivals[0].at,
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
      expect(settings.getString(SettingKeys.pendingLocationReport), isNull);
      expect(
        settings.getInt(SettingKeys.liveActivityReportedAtMs),
        greaterThanOrEqualTo(launch.millisecondsSinceEpoch),
      );
      liveActivity.dispose();
      reporter.dispose();
      positions.close();
    });
  });
}
