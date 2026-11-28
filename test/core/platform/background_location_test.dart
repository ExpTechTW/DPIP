import 'package:dpip/core/platform/background_location.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/background_location');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('start forwards platform, token, and version to the channel', () async {
    final service = BackgroundLocationService(
      platform: 1,
      version: '1.2.3',
      channel: channel,
    );

    await service.start('tok');

    expect(calls.single.method, 'start');
    expect(calls.single.arguments, {
      'platform': 1,
      'token': 'tok',
      'version': '1.2.3',
    });
  });

  test('requestAlways answers with the status the user ended on', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 'always';
    });

    expect(await BackgroundLocationService.requestAlways(channel), 'always');
    expect(calls.single.method, 'requestAlways');
  });

  test('requestAlways is null where nothing can answer', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await BackgroundLocationService.requestAlways(channel), isNull);

    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'boom'),
    );
    expect(await BackgroundLocationService.requestAlways(channel), isNull);
  });

  test('stop invokes the stop method', () async {
    final service = BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: channel,
    );

    await service.stop();

    expect(calls.single.method, 'stop');
  });

  test(
    'diagnostics keeps attempt, success, and throttle evidence separate',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        return <String, Object?>{
          'lastAttemptAt': 3000,
          'lastAttemptOk': false,
          'lastAttemptCode': 500,
          'lastSuccessAt': 2000,
          'lastSuccessCode': 202,
          'lastThrottledAt': 4000,
          'throttledCount': 7,
        };
      });
      final service = BackgroundLocationService(
        platform: 0,
        version: '1',
        channel: channel,
      );

      final diagnostics = await service.diagnostics();

      expect(diagnostics, {
        'lastAttemptAt': 3000,
        'lastAttemptOk': false,
        'lastAttemptCode': 500,
        'lastSuccessAt': 2000,
        'lastSuccessCode': 202,
        'lastThrottledAt': 4000,
        'throttledCount': 7,
      });
    },
  );

  test('clearTrack asks the native side to delete, never Dart', () async {
    final service = BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: channel,
    );

    await service.clearTrack();

    // The whole point of the round trip. The recorder caches its database
    // handle for the life of the process, so a file unlinked from Dart would
    // leave it writing into a dead inode — the rows return on the next read
    // and the space never comes back. One side owns every write, this one too.
    expect(calls.single.method, 'clearTrack');
    expect(calls.single.arguments, isNull);
  });

  test('clearTrack survives a platform with no such method', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: channel,
    );

    // A developer-page button must not throw on a platform that never recorded
    // anything — nothing to clear is not a failure.
    await expectLater(service.clearTrack(), completes);
  });

  test('clearTrack swallows a platform failure', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'disk'),
    );
    final service = BackgroundLocationService(
      platform: 0,
      version: '1',
      channel: channel,
    );

    await expectLater(service.clearTrack(), completes);
  });

  test('a platform failure is swallowed, not thrown', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'boom'),
    );
    final service = BackgroundLocationService(
      platform: 1,
      version: '1',
      channel: channel,
    );

    await expectLater(service.start('tok'), completes);
  });

  test('a missing plugin does not surface as a thrown breadcrumb drain', () async {
    // A channel with no platform implementation answers MissingPluginException
    // — the test-harness / unsupported-platform case that bootstrap hits.
    messenger.setMockMethodCallHandler(channel, null);
    final service = BackgroundLocationService(
      platform: 1,
      version: '1',
      channel: channel,
    );

    await expectLater(service.drainBreadcrumbs(), completes);
  });

  test(
    'breadcrumbs land in the log rather than the exception stream',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => ['100\tfix: thing'],
      );
      final service = BackgroundLocationService(
        platform: 1,
        version: '1',
        channel: channel,
      );

      await expectLater(service.drainBreadcrumbs(), completes);
    },
  );

  group('report heartbeat inputs', () {
    BackgroundLocationService service() => BackgroundLocationService(
      platform: 0,
      version: '1.2.3',
      channel: channel,
    );

    test('hand native the identity, the pinned point and every 2xx', () async {
      final native = service();

      expect(await native.setReportIdentity('tok'), isTrue);
      expect(await native.setManualPoint(lat: 23.97, lng: 121.6), isTrue);
      expect(await native.clearManualPoint(), isTrue);
      expect(await native.recordReport(lat: 25.03, lng: 121.52), isTrue);

      expect(calls.map((call) => call.method), [
        'setReportIdentity',
        'setManualPoint',
        'clearManualPoint',
        'recordReport',
      ]);
      expect(calls[0].arguments, {
        'platform': 0,
        'token': 'tok',
        'version': '1.2.3',
      });
      expect(calls[1].arguments, {'lat': 23.97, 'lng': 121.6});
      expect(calls[2].arguments, isNull);
      expect(calls[3].arguments, {'lat': 25.03, 'lng': 121.52});
    });

    test('are quiet no-ops where the platform has no heartbeat yet', () async {
      // iOS until phase 2: its plugin answers "not implemented", which
      // reaches Dart as MissingPluginException.
      messenger.setMockMethodCallHandler(channel, null);
      final native = service();

      expect(await native.setReportIdentity('tok'), isFalse);
      expect(await native.setManualPoint(lat: 1, lng: 2), isFalse);
      expect(await native.clearManualPoint(), isFalse);
      expect(await native.recordReport(lat: 1, lng: 2), isFalse);
    });

    test('a platform failure is logged, never thrown', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'bad_args'),
      );

      expect(await service().recordReport(lat: 1, lng: 2), isFalse);
    });
  });

  test(
    'lastSuccessAt is the later of the background success and the record',
    () async {
      var answer = <String, Object?>{'lastSuccessAt': 2000, 'reportedAt': 5000};
      messenger.setMockMethodCallHandler(channel, (_) async => answer);
      final native = BackgroundLocationService(
        platform: 0,
        version: '1',
        channel: channel,
      );

      expect(
        await native.lastSuccessAt(),
        DateTime.fromMillisecondsSinceEpoch(5000, isUtc: true),
      );
      answer = {'lastSuccessAt': 7000, 'reportedAt': 5000};
      expect(
        await native.lastSuccessAt(),
        DateTime.fromMillisecondsSinceEpoch(7000, isUtc: true),
      );
      answer = {'lastSuccessAt': null};
      expect(await native.lastSuccessAt(), isNull);
    },
  );
}
