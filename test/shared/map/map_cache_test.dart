import 'package:dpip/shared/map/map_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.exptech.dpip/map_cache');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'setMaximumSize invokes the native channel with the byte count',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return null;
      });

      await const MapCache().setMaximumSize(64 * 1024 * 1024);

      expect(received?.method, 'setMaximumAmbientCacheSize');
      expect((received!.arguments as Map)['bytes'], 64 * 1024 * 1024);
    },
  );

  test('a missing native handler degrades to a no-op (never throws)', () async {
    // No mock handler → MissingPluginException, which MapCache swallows.
    await expectLater(const MapCache().setMaximumSize(1024), completes);
  });

  test('a native error is swallowed (best-effort, never throws)', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'cache_failed', message: 'boom');
    });

    await expectLater(const MapCache().setMaximumSize(1024), completes);
  });
}
