/// The DPIP MCP server as the AI chat's [ToolHost].
///
/// MCP over Streamable HTTP is JSON-RPC 2.0 in a POST; the answer comes back
/// either as JSON or as a short event stream carrying the same JSON. Only the
/// three methods a client of read-only tools needs are spoken: `initialize`
/// (for the server's usage notes), `tools/list`, and `tools/call`.
///
/// Calls go through the region-aware [ApiClient] on [ApiTier.coreApi], like
/// every other DPIP request, so a region that is down fails over. The server
/// is stateless, so a failed-over call needs no new session; if it ever hands
/// out a session id, it is echoed back, and a 404 on it starts a new one.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';

class DpipMcpToolHost implements ToolHost {
  DpipMcpToolHost(this._api);

  final ApiClient _api;

  static const String protocolVersion = '2025-06-18';

  ToolCatalog? _catalog;
  Future<ToolCatalog>? _loading;
  String? _session;
  int _nextId = 1;

  /// Listed once per session: the tools change only when the server is
  /// deployed, and a stale list costs at most an "unknown tool" answer.
  @override
  Future<ToolCatalog> catalog() async {
    final cached = _catalog;
    if (cached != null) return cached;
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<ToolCatalog> _load() async {
    try {
      final init = await _rpc('initialize', {
        'protocolVersion': protocolVersion,
        'capabilities': const <String, Object?>{},
        'clientInfo': const {'name': 'dpip', 'version': '1'},
      });
      await _notify('notifications/initialized');
      final tools = <ToolSpec>[];
      String? cursor;
      // Bounded: a server that keeps returning a cursor is not followed
      // forever.
      for (var page = 0; page < 10; page++) {
        final result = await _rpc('tools/list', {'cursor': ?cursor});
        for (final tool in (result['tools'] as List? ?? const [])) {
          if (tool is! Map) continue;
          final name = tool['name'];
          if (name is! String || name.isEmpty) continue;
          final schema = tool['inputSchema'];
          tools.add(
            ToolSpec(
              name: name,
              description: (tool['description'] as String?) ?? '',
              parameters: schema is Map
                  ? schema.cast<String, Object?>()
                  : const {'type': 'object', 'properties': <String, Object?>{}},
            ),
          );
        }
        cursor = result['nextCursor'] as String?;
        if (cursor == null) break;
      }
      if (tools.isEmpty) throw const FormatException('no tools');
      final instructions = init['instructions'];
      return _catalog = ToolCatalog(
        tools: List.unmodifiable(tools),
        instructions: instructions is String ? instructions : null,
      );
    } on AiException {
      rethrow;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ai chat: listing the DPIP tools');
      throw const AiException(AiFailureKind.toolsUnavailable);
    }
  }

  @override
  Future<ToolOutcome> call(String name, Map<String, Object?> arguments) async {
    try {
      final result = await _rpc('tools/call', {
        'name': name,
        'arguments': arguments,
      });
      final structured = result['structuredContent'];
      final content = structured != null
          ? jsonEncode(structured)
          : [
              for (final part in (result['content'] as List? ?? const []))
                if (part is Map && part['type'] == 'text') part['text'],
            ].join('\n');
      return ToolOutcome(content, isError: result['isError'] == true);
    } on _RpcError catch (error) {
      // Bad arguments and the like: the model can read this and try again.
      return ToolOutcome(error.message, isError: true);
    } catch (error) {
      Log.warning('ai chat: tool $name failed (${error.runtimeType})');
      return const ToolOutcome(
        'The DPIP data server could not be reached.',
        isError: true,
      );
    }
  }

  Future<Map<String, Object?>> _rpc(
    String method,
    Map<String, Object?> params, {
    bool retried = false,
  }) async {
    final id = _nextId++;
    final Response<dynamic> response;
    try {
      response = await _post({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
    } on DioException catch (error) {
      // An expired session: start a new one, once. Only from a tool call —
      // the listing *is* the new session, and waiting on it from inside it
      // would never finish.
      if (!retried &&
          _session != null &&
          error.response?.statusCode == 404 &&
          method == 'tools/call') {
        _session = null;
        _catalog = null;
        await catalog();
        return _rpc(method, params, retried: true);
      }
      rethrow;
    }
    final message = await _find(response, id);
    final error = message['error'];
    if (error is Map) {
      throw _RpcError(
        (error['message'] as String?) ?? 'error ${error['code']}',
      );
    }
    final result = message['result'];
    if (result is! Map) throw const FormatException('no result');
    return result.cast<String, Object?>();
  }

  Future<void> _notify(String method) async {
    await _post({'jsonrpc': '2.0', 'method': method});
  }

  Future<Response<dynamic>> _post(Map<String, Object?> body) async {
    final response = await _api.request(
      ApiTier.coreApi,
      ApiPaths.mcp,
      method: 'POST',
      data: jsonEncode(body),
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.plain,
        // A tool that reaches several sources (a year of reports) can take a
        // few seconds; the client-wide 10 s would cut it short.
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json, text/event-stream',
          'MCP-Protocol-Version': protocolVersion,
          if (_session != null) 'Mcp-Session-Id': _session,
        },
      ),
    );
    final session = response.headers.value('mcp-session-id');
    if (session != null && session.isNotEmpty) _session = session;
    return response;
  }

  /// The JSON-RPC message answering [id], from a JSON or event-stream body.
  static Future<Map<String, Object?>> _find(
    Response<dynamic> response,
    int id,
  ) async {
    final body = response.data is String ? response.data as String : '';
    final type = response.headers.value(Headers.contentTypeHeader) ?? '';
    final candidates = <Object?>[];
    if (type.contains('text/event-stream')) {
      await for (final event in HttpSseClient.parse(
        Stream.value(utf8.encode(body)),
      )) {
        if (event.isDefault && event.data.isNotEmpty) {
          candidates.add(jsonDecode(event.data));
        }
      }
    } else {
      final json = jsonDecode(body);
      json is List ? candidates.addAll(json) : candidates.add(json);
    }
    for (final candidate in candidates) {
      if (candidate is Map && candidate['id'] == id) {
        return candidate.cast<String, Object?>();
      }
    }
    throw const FormatException('no answer for the request');
  }
}

final class _RpcError implements Exception {
  const _RpcError(this.message);

  final String message;
}
