import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/ai_chat/data/dpip_mcp_tool_host.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

/// A JSON-RPC answer as the server sends it: one SSE `message` event.
Response<dynamic> _sse(Object message, {Map<String, List<String>>? headers}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: 200,
      headers: Headers.fromMap({
        Headers.contentTypeHeader: ['text/event-stream'],
        ...?headers,
      }),
      data: 'event: message\ndata: ${jsonEncode(message)}\n\n',
    );

Response<dynamic> _json(Object message) => Response<dynamic>(
  requestOptions: RequestOptions(),
  statusCode: 200,
  headers: Headers.fromMap({
    Headers.contentTypeHeader: ['application/json'],
  }),
  data: jsonEncode(message),
);

void main() {
  late FakeApi api;
  late List<ApiTier> tiers;
  late Map<String, Object? Function(Map<String, Object?> params)> results;

  setUp(() {
    api = FakeApi();
    tiers = [];
    results = {
      'initialize': (_) => {'instructions': 'Times are Unix seconds.'},
      'tools/list': (_) => {
        'tools': [
          {
            'name': 'eew',
            'description': 'warnings',
            'inputSchema': {'type': 'object'},
          },
          {'description': 'nameless, skipped'},
        ],
      },
    };
    api.onRequest = (tier, request) async {
      tiers.add(tier);
      final body = request.json;
      final method = body['method'] as String;
      if (!body.containsKey('id')) {
        return Response(requestOptions: RequestOptions(), statusCode: 202);
      }
      final params = (body['params'] as Map?)?.cast<String, Object?>() ?? {};
      final answer = results[method]!(params);
      return _sse({
        'jsonrpc': '2.0',
        'id': body['id'],
        if (answer is Map && answer.containsKey('error'))
          'error': answer['error']
        else
          'result': answer,
      });
    };
  });

  List<String> methods() => [
    for (final r in api.seen) r.json['method'] as String,
  ];

  test('lists tools once, after initializing, on the core tier', () async {
    final host = DpipMcpToolHost(api);
    final catalog = await host.catalog();
    await host.catalog();

    expect(methods(), [
      'initialize',
      'notifications/initialized',
      'tools/list',
    ]);
    expect(tiers.toSet(), {ApiTier.coreApi});
    expect(api.seen.map((r) => r.url).toSet(), {ApiPaths.mcp});
    final headers = api.seen.first.headers;
    expect(headers['Accept'], 'application/json, text/event-stream');
    expect(headers['MCP-Protocol-Version'], DpipMcpToolHost.protocolVersion);

    expect(catalog.tools.map((t) => t.name), ['eew']);
    expect(catalog.instructions, 'Times are Unix seconds.');
  });

  test('follows the cursor across pages', () async {
    results['tools/list'] = (params) => params['cursor'] == null
        ? {
            'tools': [
              {'name': 'a', 'inputSchema': <String, Object>{}},
            ],
            'nextCursor': 'p2',
          }
        : {
            'tools': [
              {'name': 'b', 'inputSchema': <String, Object>{}},
            ],
          };
    final catalog = await DpipMcpToolHost(api).catalog();
    expect(catalog.tools.map((t) => t.name), ['a', 'b']);
  });

  test('a tool answers with its structured content', () async {
    results['tools/call'] = (params) => {
      'content': [
        {'type': 'text', 'text': 'ignored when structured content exists'},
      ],
      'structuredContent': {'data': <Object>[], 'name': params['name']},
    };
    final outcome = await DpipMcpToolHost(api).call('eew', {'at': 1});
    expect(outcome.isError, isFalse);
    expect(jsonDecode(outcome.content), {'data': <Object>[], 'name': 'eew'});
    expect(api.seen.single.json['params'], {
      'name': 'eew',
      'arguments': {'at': 1},
    });
  });

  test('a tool error and an RPC error both come back to the model', () async {
    final host = DpipMcpToolHost(api);
    results['tools/call'] = (_) => {
      'isError': true,
      'content': [
        {'type': 'text', 'text': 'bad station'},
      ],
    };
    final toolError = await host.call('eew', {});
    expect(toolError.isError, isTrue);
    expect(toolError.content, 'bad station');

    results['tools/call'] = (_) => {
      'error': {'code': -32602, 'message': 'Invalid params'},
    };
    final rpcError = await host.call('eew', {});
    expect(rpcError.isError, isTrue);
    expect(rpcError.content, 'Invalid params');
  });

  test('a plain JSON answer is read too', () async {
    api.onRequest = (tier, request) async => _json({
      'jsonrpc': '2.0',
      'id': request.json['id'],
      'result': {
        'content': [
          {'type': 'text', 'text': 'one'},
          {'type': 'text', 'text': 'two'},
        ],
      },
    });
    final outcome = await DpipMcpToolHost(api).call('eew', {});
    expect(outcome.content, 'one\ntwo');
  });

  test('an unreachable server fails the listing, not a single call', () async {
    api.onRequest = (_, _) async => throw DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    );
    final host = DpipMcpToolHost(api);
    await expectLater(
      host.catalog(),
      throwsA(
        isA<AiException>().having(
          (e) => e.kind,
          'kind',
          AiFailureKind.toolsUnavailable,
        ),
      ),
    );
    final outcome = await host.call('eew', {});
    expect(outcome.isError, isTrue);
  });

  test('a session id the server hands out is sent back', () async {
    final base = api.onRequest!;
    api.onRequest = (tier, request) async {
      final response = await base(tier, request);
      if (request.json['method'] == 'initialize') {
        return _sse(
          jsonDecode((response.data as String).split('data: ').last.trim())
              as Object,
          headers: {
            'mcp-session-id': ['s-1'],
          },
        );
      }
      return response;
    };
    await DpipMcpToolHost(api).catalog();
    expect(api.seen.first.headers.containsKey('Mcp-Session-Id'), isFalse);
    expect(api.seen.last.headers['Mcp-Session-Id'], 's-1');
  });
}
