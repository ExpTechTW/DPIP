import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_settings_repository.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the key each model listing was sent with.
class _Settings implements AiSettingsRepository {
  _Settings(this.connection, this.key);

  @override
  AiConnection connection;
  String? key;

  final List<String?> listedKeys = [];

  @override
  bool get introSeen => false;

  @override
  Future<void> markIntroSeen() async {}

  @override
  Future<String?> apiKey() async => key;

  @override
  Future<void> save(AiConnection connection, {String? apiKey}) async {
    final previousUrl = this.connection.baseUrl;
    this.connection = connection;
    if (apiKey != null) {
      key = apiKey.isEmpty ? null : apiKey;
    } else if (previousUrl.isNotEmpty && previousUrl != connection.baseUrl) {
      key = null;
    }
  }

  @override
  Future<void> forget() async {
    connection = AiConnection.empty;
    key = null;
  }

  @override
  Future<List<String>> listModels(String baseUrl, String? apiKey) async {
    listedKeys.add(apiKey);
    return const [];
  }
}

void main() {
  test(
    'the saved key is listed with, but never sent to a new service',
    () async {
      final settings = _Settings(
        const AiConnection(baseUrl: 'https://a.example/v1', model: 'm'),
        'sk-saved',
      );
      final setup = AiSetup(settings);

      await setup.listModels(settings.connection.baseUrl, '');
      await setup.listModels('https://b.example/v1', '');
      await setup.listModels('https://b.example/v1', 'typed');

      expect(settings.listedKeys, ['sk-saved', null, 'typed']);
    },
  );
}
