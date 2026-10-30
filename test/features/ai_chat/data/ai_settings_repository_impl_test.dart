import 'dart:convert';

import 'package:dpip/core/platform/secret_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/ai_chat/data/ai_settings_repository_impl.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late SettingsStore settings;
  late FakeSecretStore secrets;
  late FakeApi api;
  late AiSettingsRepositoryImpl repository;

  setUp(() {
    settings = SettingsStore.inMemory();
    secrets = FakeSecretStore();
    api = FakeApi();
    repository = AiSettingsRepositoryImpl(settings, secrets, api);
  });

  const connection = AiConnection(
    baseUrl: 'https://ai.example/v1',
    model: 'm-1',
  );

  test('the key goes to key storage, never to settings', () async {
    await repository.save(connection, apiKey: '  sk-secret  ');
    expect(secrets.values[SecretKey.aiApiKey], 'sk-secret');
    expect(settings.getString(SettingKeys.aiBaseUrl), connection.baseUrl);
    expect(settings.getString(SettingKeys.aiModel), connection.model);
    // Nothing in settings holds the key.
    for (final key in [SettingKeys.aiBaseUrl, SettingKeys.aiModel]) {
      expect(settings.getString(key), isNot(contains('sk-secret')));
    }
    expect(await repository.apiKey(), 'sk-secret');
  });

  test('no key keeps the saved one; an empty key removes it', () async {
    await repository.save(connection, apiKey: 'sk-1');
    await repository.save(connection);
    expect(await repository.apiKey(), 'sk-1');
    await repository.save(connection, apiKey: '');
    expect(await repository.apiKey(), isNull);
  });

  test('a refused key changes nothing else', () async {
    secrets.refuseWrites = true;
    await expectLater(
      repository.save(connection, apiKey: 'k'),
      throwsStateError,
    );
    expect(repository.connection.baseUrl, isEmpty);
  });

  test('forget removes the URL, the model and the key', () async {
    await repository.save(connection, apiKey: 'sk-1');
    await repository.forget();
    expect(repository.connection.isComplete, isFalse);
    expect(await repository.apiKey(), isNull);
  });

  test('the intro is shown until it is marked seen', () async {
    expect(repository.introSeen, isFalse);
    await repository.markIntroSeen();
    expect(repository.introSeen, isTrue);
  });

  group('listing models', () {
    test('reads ids, sorted and once each, with the key', () async {
      api.onStream = (_) async => streamed(
        200,
        Stream.value(
          utf8.encode(
            jsonEncode({
              'data': [
                {'id': 'b'},
                {'id': 'a'},
                {'id': 'b'},
                {'object': 'no id'},
              ],
            }),
          ),
        ),
        contentType: 'application/json',
      );
      final ids = await repository.listModels('https://ai.example/v1', 'k');
      expect(ids, ['a', 'b']);
      final request = api.seen.single;
      expect(request.method, 'GET');
      expect(request.url, 'https://ai.example/v1/models');
      expect(request.headers['Authorization'], 'Bearer k');
    });

    test('a 401 is reported as an unauthorized key', () async {
      api.onStream = (_) async => streamed(
        401,
        Stream.value(utf8.encode('{"error":{"message":"bad key"}}')),
        contentType: 'application/json',
      );
      await expectLater(
        repository.listModels('https://ai.example/v1', 'k'),
        throwsA(
          isA<AiException>()
              .having((e) => e.kind, 'kind', AiFailureKind.unauthorized)
              .having((e) => e.detail, 'detail', 'bad key'),
        ),
      );
    });

    test('an answer that is not a model list is a bad response', () async {
      api.onStream = (_) async =>
          streamed(200, Stream.value(utf8.encode('<html>')));
      await expectLater(
        repository.listModels('https://ai.example/v1', null),
        throwsA(
          isA<AiException>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.badResponse,
          ),
        ),
      );
    });
  });
}
