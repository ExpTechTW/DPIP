/// The AI chat's setup as the pages watch it.
library;

import 'dart:async';

import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_settings_repository.dart';
import 'package:flutter/foundation.dart';

class AiSetup extends ChangeNotifier {
  AiSetup(this._repository) {
    unawaited(_loadKey());
  }

  final AiSettingsRepository _repository;

  bool? _hasKey;

  bool get introSeen => _repository.introSeen;

  AiConnection get connection => _repository.connection;

  /// Whether a key is saved — false until the key storage has answered.
  bool get hasKey => _hasKey ?? false;

  /// Enough to start a conversation. A key is not required: a service on
  /// this phone may need none, and a missing one is reported by the service
  /// itself, more precisely than a guess here could.
  bool get ready => connection.isComplete;

  Future<void> _loadKey() async {
    final key = await _repository.apiKey();
    _hasKey = key != null && key.isNotEmpty;
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    await _repository.markIntroSeen();
    notifyListeners();
  }

  /// See [AiSettingsRepository.save]: a null [apiKey] keeps the saved one.
  Future<void> save(AiConnection connection, {String? apiKey}) async {
    await _repository.save(connection, apiKey: apiKey);
    if (apiKey != null) _hasKey = apiKey.trim().isNotEmpty;
    notifyListeners();
  }

  Future<void> forget() async {
    await _repository.forget();
    _hasKey = false;
    notifyListeners();
  }

  /// Model ids at [baseUrl]; with no [apiKey] typed, the saved key is used.
  Future<List<String>> listModels(String baseUrl, String? apiKey) async {
    final typed = apiKey?.trim();
    final key = typed == null || typed.isEmpty
        ? await _repository.apiKey()
        : typed;
    return _repository.listModels(baseUrl, key);
  }
}
