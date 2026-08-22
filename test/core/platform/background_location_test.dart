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
}
