/// The AI chat's setup, kept on this phone.
///
/// The base URL and model are ordinary settings. The key is not: it goes to
/// the platform's key storage ([SecretStore]), which a backup restored onto
/// another phone does not carry.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/platform/secret_store.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/ai_chat/data/ai_http.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/ai_settings_repository.dart';

class AiSettingsRepositoryImpl implements AiSettingsRepository {
  AiSettingsRepositoryImpl(this._settings, this._secrets, this._api);

  final SettingsStore _settings;
  final SecretStore _secrets;
  final ApiClient _api;

  @override
  bool get introSeen => _settings.getBool(SettingKeys.aiIntroSeen) ?? false;

  @override
  Future<void> markIntroSeen() =>
      _settings.setBool(SettingKeys.aiIntroSeen, true);

  @override
  AiConnection get connection => AiConnection(
    baseUrl: _settings.getString(SettingKeys.aiBaseUrl) ?? '',
    model: _settings.getString(SettingKeys.aiModel) ?? '',
  );

  @override
  Future<String?> apiKey() => _secrets.read(SecretKey.aiApiKey);

  @override
  Future<void> save(AiConnection connection, {String? apiKey}) async {
    // The key first: if the platform refuses it, nothing else changes and
    // the page can say so.
    if (apiKey != null) {
      final key = apiKey.trim();
      key.isEmpty
          ? await _secrets.delete(SecretKey.aiApiKey)
          : await _secrets.write(SecretKey.aiApiKey, key);
    }
    await _settings.setString(SettingKeys.aiBaseUrl, connection.baseUrl);
    await _settings.setString(SettingKeys.aiModel, connection.model);
  }

  @override
  Future<void> forget() async {
    await _secrets.delete(SecretKey.aiApiKey);
    await _settings.remove(SettingKeys.aiBaseUrl);
    await _settings.remove(SettingKeys.aiModel);
  }

  @override
  Future<List<String>> listModels(String baseUrl, String? apiKey) async {
    final key = apiKey?.trim();
    final Object? json;
    try {
      // Streamed, so the answer is never cached: it depends on the key.
      final response = await _api.streamAbsolute(
        '$baseUrl/models',
        method: 'GET',
        headers: {
          if (key != null && key.isNotEmpty) 'Authorization': 'Bearer $key',
        },
        idleTimeout: const Duration(seconds: 15),
      );
      final status = response.statusCode ?? 0;
      final text = await readText(response.data!.stream, 4 * 1024 * 1024);
      if (status < 200 || status >= 300) {
        throw aiExceptionForStatus(status, text);
      }
      json = jsonDecode(text);
    } on DioException catch (error) {
      throw aiExceptionForDio(error) ??
          const AiException(AiFailureKind.network);
    } on FormatException {
      throw const AiException(AiFailureKind.badResponse);
    }
    final data = json is Map ? json['data'] ?? json['models'] : json;
    if (data is! List) throw const AiException(AiFailureKind.badResponse);
    final ids = <String>{
      for (final entry in data)
        if (entry is Map && entry['id'] is String)
          entry['id'] as String
        else if (entry is Map && entry['name'] is String)
          entry['name'] as String,
    }.toList()..sort();
    return ids;
  }
}
