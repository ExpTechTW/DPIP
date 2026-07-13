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
}
