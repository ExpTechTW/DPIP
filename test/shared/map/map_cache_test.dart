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

  test('defaults to the shared ambient ceiling', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    await const MapCache().setMaximumSize();

    expect((received!.arguments as Map)['bytes'], MapCache.defaultAmbientBytes);
  });

  test('a missing native handler degrades to a no-op (never throws)', () async {
    await expectLater(const MapCache().setMaximumSize(1024), completes);
  });
}
