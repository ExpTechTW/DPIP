import 'package:dpip/core/platform/secret_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.exptech.dpip/secret_store.test');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => calls.clear());
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void answer(Object? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });

  test('names the secret, and sends the value only to write', () async {
    final store = PlatformSecretStore(channel: channel);
    answer((call) => call.method == 'read' ? 'sk-1' : null);

    expect(await store.read(SecretKey.aiApiKey), 'sk-1');
    await store.write(SecretKey.aiApiKey, 'sk-2');
    await store.delete(SecretKey.aiApiKey);

    expect(calls.map((c) => c.method), ['read', 'write', 'delete']);
    expect(calls[0].arguments, {'key': 'ai.apiKey'});
    expect(calls[1].arguments, {'key': 'ai.apiKey', 'value': 'sk-2'});
    expect(calls[2].arguments, {'key': 'ai.apiKey'});
  });

  test('an unreadable secret reads as absent', () async {
    answer((_) => throw PlatformException(code: 'failed'));
    expect(
      await PlatformSecretStore(channel: channel).read(SecretKey.aiApiKey),
      isNull,
    );
  });

  test('a refused write is reported to the caller', () async {
    answer((_) => throw PlatformException(code: 'keychain'));
    await expectLater(
      PlatformSecretStore(channel: channel).write(SecretKey.aiApiKey, 'k'),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'without a platform side, nothing is stored and nothing breaks',
    () async {
      final store = PlatformSecretStore(channel: channel);
      expect(await store.read(SecretKey.aiApiKey), isNull);
      await store.delete(SecretKey.aiApiKey);
      // A write must not look saved when nothing could store it.
      await expectLater(
        store.write(SecretKey.aiApiKey, 'k'),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );
}
