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

  test('preload invokes the native channel with url and bytes', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    await const MapCache().preload(
      url: 'https://example/t.webp',
      data: Uint8List.fromList([1, 2, 3]),
      etag: 'W/"1"',
    );

    expect(received?.method, 'preload');
    final args = received!.arguments as Map;
    expect(args['url'], 'https://example/t.webp');
    expect(args['etag'], 'W/"1"');
    expect(args['data'], Uint8List.fromList([1, 2, 3]));
  });

  test('a missing native handler degrades to a no-op (never throws)', () async {
    await expectLater(const MapCache().setMaximumSize(1024), completes);
    await expectLater(
      const MapCache().preload(url: 'https://x', data: Uint8List(0)),
      completes,
    );
  });
}
