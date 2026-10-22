/// Where the AI chat's setup is kept: on this phone, and nowhere else.
library;

import 'package:dpip/features/ai_chat/domain/ai_connection.dart';

abstract class AiSettingsRepository {
  /// Whether the explanation page has been read and dismissed.
  bool get introSeen;

  Future<void> markIntroSeen();

  /// The saved service; [AiConnection.empty] when there is none.
  AiConnection get connection;

  /// The saved API key, read from the platform's key storage.
  Future<String?> apiKey();

  /// Saves [connection]. A null [apiKey] keeps the key already saved; an
  /// empty one removes it (a local service may need none). Throws when the
  /// key could not be stored.
  Future<void> save(AiConnection connection, {String? apiKey});

  /// Removes the service, the model and the key.
  Future<void> forget();

  /// The model ids [baseUrl] offers, for picking one. Throws an `AiException`.
  Future<List<String>> listModels(String baseUrl, String? apiKey);
}
