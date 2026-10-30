/// A [ChatModel] over any OpenAI-compatible `/chat/completions` endpoint.
///
/// That one wire format reaches OpenAI, Gemini, Anthropic, OpenRouter, Groq
/// and the common self-hosted servers (vLLM, Ollama, LM Studio, llama.cpp),
/// each with small deviations handled in [CompletionDecoder].
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/features/ai_chat/data/ai_http.dart';
import 'package:dpip/features/ai_chat/data/think_filter.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';

class OpenAiChatModel implements ChatModel {
  OpenAiChatModel(
    this._api,
    this._connection,
    this._apiKey, {
    this.idleTimeout = const Duration(seconds: 120),
  });

  final ApiClient _api;
  final AiConnection _connection;
  final String? _apiKey;

  /// The longest silence tolerated mid-answer. Generous on purpose: a large
  /// model on one shared GPU can queue a request, then think, before its
  /// first word.
  final Duration idleTimeout;

  @override
  Stream<ModelEvent> complete({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
  }) {
    final cancel = CancelToken();
    late final StreamController<ModelEvent> out;
    out = StreamController<ModelEvent>(
      onListen: () => unawaited(_run(out, cancel, messages, tools)),
      onCancel: () {
        if (!cancel.isCancelled) cancel.cancel();
      },
    );
    return out.stream;
  }

  Future<void> _run(
    StreamController<ModelEvent> out,
    CancelToken cancel,
    List<ChatMessage> messages,
    List<ToolSpec> tools,
  ) async {
    try {
      final key = _apiKey;
      final response = await _api.streamAbsolute(
        '${_connection.baseUrl}/chat/completions',
        data: jsonEncode({
          'model': _connection.model,
          'messages': [for (final m in messages) encodeMessage(m)],
          if (tools.isNotEmpty) 'tools': [for (final t in tools) encodeTool(t)],
          'stream': true,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream, application/json',
          if (key != null && key.isNotEmpty) 'Authorization': 'Bearer $key',
        },
        idleTimeout: idleTimeout,
        cancelToken: cancel,
      );
      final status = response.statusCode ?? 0;
      final body = response.data!.stream;
      if (status < 200 || status >= 300) {
        throw aiExceptionForStatus(status, await readText(body, 16 * 1024));
      }
      final decoder = CompletionDecoder();
      final type = response.headers.value(Headers.contentTypeHeader) ?? '';
      if (type.contains('text/event-stream')) {
        await for (final event in HttpSseClient.parse(body)) {
          if (!event.isDefault) continue;
          final data = event.data.trim();
          if (data.isEmpty) continue;
          if (data == '[DONE]') break;
          decoder.chunk(jsonDecode(data)).forEach(out.add);
        }
      } else {
        // A service that ignores `stream: true` sends one JSON body.
        decoder
            .chunk(jsonDecode(await readText(body, 4 * 1024 * 1024)))
            .forEach(out.add);
      }
      final (:tail, :message) = decoder.finish();
      tail.forEach(out.add);
      out.add(ModelDone(message));
    } on DioException catch (error) {
      final failure = aiExceptionForDio(error);
      if (failure != null) out.addError(failure);
    } on AiException catch (error) {
      out.addError(error);
    } on FormatException {
      out.addError(const AiException(AiFailureKind.badResponse));
    } finally {
      // Not awaited: after a cancellation the close never completes, since
      // no one is left to receive the done event.
      unawaited(out.close());
    }
  }

  /// One message in the wire format.
  static Map<String, Object?> encodeMessage(ChatMessage message) =>
      switch (message) {
        SystemMessage(:final text) => {'role': 'system', 'content': text},
        UserMessage(:final text) => {'role': 'user', 'content': text},
        AssistantMessage(:final text, :final toolCalls) => {
          'role': 'assistant',
          // null, not absent, beside tool calls: it is what the services
          // themselves return there, so it is the form every one accepts.
          'content': text.isEmpty && toolCalls.isNotEmpty ? null : text,
          if (toolCalls.isNotEmpty)
            'tool_calls': [
              for (final call in toolCalls)
                {
                  'id': call.id,
                  'type': 'function',
                  'function': {
                    'name': call.name,
                    'arguments': call.arguments.isEmpty ? '{}' : call.arguments,
                  },
                },
            ],
        },
        ToolResultMessage(:final callId, :final content) => {
          'role': 'tool',
          'tool_call_id': callId,
          'content': content,
        },
      };

  /// One tool in the wire format, its schema reduced to what every service
  /// accepts (see [sanitizeSchema]).
  static Map<String, Object?> encodeTool(ToolSpec tool) => {
    'type': 'function',
    'function': {
      'name': tool.name,
      'description': tool.description,
      'parameters': sanitizeSchema(tool.parameters),
    },
  };

  /// [schema] without the JSON Schema features some services reject.
  ///
  /// The DPIP server writes optional parameters as `"type": ["null", "integer"]`
  /// and closes objects with `additionalProperties`; OpenAI takes both, but
  /// Gemini's compatible endpoint refuses the whole request over either. A
  /// nullable type becomes its non-null type (leaving the parameter out says
  /// the same), and the extra keywords are dropped — they constrain, they do
  /// not describe, and the server validates the call regardless.
  static Map<String, Object?> sanitizeSchema(Map<String, Object?> schema) {
    final out = <String, Object?>{};
    for (final MapEntry(:key, :value) in schema.entries) {
      if (key == r'$schema' || key == 'additionalProperties') continue;
      out[key] = switch ((key, value)) {
        ('type', final List<Object?> types) => types.firstWhere(
          (t) => t != 'null',
          orElse: () => 'string',
        ),
        ('enum', final List<Object?> values) => [for (final v in values) ?v],
        // Keys under `properties` are parameter names, not keywords: keep
        // them all, clean each parameter's own schema.
        ('properties', final Map<Object?, Object?> properties) => {
          for (final MapEntry(:key, :value) in properties.entries)
            key.toString(): _sanitizeValue(value),
        },
        _ => _sanitizeValue(value),
      };
    }
    if (out['type'] == 'object' && !out.containsKey('properties')) {
      out['properties'] = const <String, Object?>{};
    }
    return out;
  }

  static Object? _sanitizeValue(Object? value) => switch (value) {
    final Map<Object?, Object?> map => sanitizeSchema(
      map.map((k, v) => MapEntry(k.toString(), v)),
    ),
    final List<Object?> list => [for (final v in list) _sanitizeValue(v)],
    _ => value,
  };
}

/// Assembles a streamed completion: text deltas, reasoning, and tool calls
/// that arrive in pieces.
class CompletionDecoder {
  final StringBuffer _text = StringBuffer();
  final ThinkFilter _think = ThinkFilter();
  final Map<int, _CallBuilder> _calls = {};

  /// Events for one decoded chunk — or for a whole non-streamed response,
  /// whose `message` is read like a single `delta`.
  Iterable<ModelEvent> chunk(Object? json) sync* {
    if (json is! Map) throw const FormatException('not an object');
    final error = json['error'];
    if (error != null) {
      // Some services report a failure inside a 200 stream (OpenRouter sends
      // an upstream 429 this way).
      final code = error is Map ? error['code'] : null;
      final body = jsonEncode(json);
      throw code is int && code >= 400
          ? aiExceptionForStatus(code, body)
          : AiException(AiFailureKind.server, detail: errorDetail(body));
    }
    final choices = json['choices'];
    // A usage-only chunk, or a keep-alive some proxies insert.
    if (choices is! List || choices.isEmpty) return;
    final choice = choices.first;
    if (choice is! Map) return;
    final delta = choice['delta'] ?? choice['message'];
    if (delta is! Map) return;

    final reasoning = delta['reasoning_content'] ?? delta['reasoning'];
    if (reasoning is String && reasoning.isNotEmpty) {
      yield const ModelThinking();
    }
    final content = delta['content'];
    if (content is String && content.isNotEmpty) {
      final visible = _think.add(content);
      if (_think.thinking) yield const ModelThinking();
      if (visible.isNotEmpty) {
        _text.write(visible);
        yield ModelText(visible);
      }
    }
    final toolCalls = delta['tool_calls'];
    if (toolCalls is List) {
      for (final call in toolCalls) {
        if (call is Map) _absorbCall(call);
      }
    }
  }

  void _absorbCall(Map<Object?, Object?> call) {
    final id = call['id'];
    final index = switch (call['index']) {
      final int i => i,
      // No index (some compatible servers): an id names the call; with
      // neither, a piece continues the call before it.
      _ when id is String && id.isNotEmpty =>
        _calls.entries
                .where((e) => e.value.id == id)
                .map((e) => e.key)
                .firstOrNull ??
            _calls.length,
      _ => _calls.isEmpty ? 0 : _calls.keys.reduce((a, b) => a > b ? a : b),
    };
    final builder = _calls.putIfAbsent(index, _CallBuilder.new);
    if (id is String && id.isNotEmpty) builder.id ??= id;
    final function = call['function'];
    if (function is! Map) return;
    final name = function['name'];
    // Set once: a few servers repeat the name in every piece.
    if (name is String && name.isNotEmpty && builder.name.isEmpty) {
      builder.name = name;
    }
    switch (function['arguments']) {
      case final String piece:
        builder.arguments.write(piece);
      case final Map<Object?, Object?> whole:
        builder.arguments
          ..clear()
          ..write(jsonEncode(whole));
    }
  }

  /// The text still held back, and the finished message.
  ({List<ModelEvent> tail, AssistantMessage message}) finish() {
    final rest = _think.flush();
    _text.write(rest);
    final indices = _calls.keys.toList()..sort();
    return (
      tail: [if (rest.isNotEmpty) ModelText(rest)],
      message: AssistantMessage(
        text: _text.toString(),
        toolCalls: [
          for (final i in indices)
            if (_calls[i]!.name.isNotEmpty)
              ToolCall(
                id: _calls[i]!.id ?? 'call_$i',
                name: _calls[i]!.name,
                arguments: _calls[i]!.arguments.toString(),
              ),
        ],
      ),
    );
  }
}

class _CallBuilder {
  String? id;
  String name = '';
  final StringBuffer arguments = StringBuffer();
}
