import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/features/ai_chat/data/openai_chat_model.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

const _connection = AiConnection(
  baseUrl: 'https://ai.example/v1',
  model: 'm-1',
);

const _tool = ToolSpec(
  name: 'eew',
  description: 'warnings',
  parameters: {
    'type': 'object',
    'properties': {
      'at': {
        'type': ['null', 'integer'],
      },
    },
    'additionalProperties': false,
  },
);

void main() {
  late FakeApi api;

  setUp(() => api = FakeApi());

  Future<List<ModelEvent>> complete({String? key = 'sk-1'}) =>
      OpenAiChatModel(api, _connection, key)
          .complete(messages: const [UserMessage('hi')], tools: const [_tool])
          .toList();

  group('the request', () {
    test('posts the conversation and tools, streamed, with the key', () async {
      api.onStream = (_) async => streamed(200, sse([textChunk('ok')]));
      await complete();
      final request = api.seen.single;
      expect(request.method, 'POST');
      expect(request.url, 'https://ai.example/v1/chat/completions');
      expect(request.headers['Authorization'], 'Bearer sk-1');
      final body = request.json;
      expect(body['model'], 'm-1');
      expect(body['stream'], isTrue);
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
      final tools = body['tools']! as List;
      final function = (tools.single as Map)['function'] as Map;
      expect(function['name'], 'eew');
      // Simplified for the pickier services.
      expect(function['parameters'], {
        'type': 'object',
        'properties': {
          'at': {'type': 'integer'},
        },
      });
    });

    test('sends no Authorization header without a key', () async {
      api.onStream = (_) async => streamed(200, sse([textChunk('ok')]));
      await complete(key: null);
      expect(api.seen.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('the answer', () {
    test('streams text and ends with the whole message', () async {
      api.onStream = (_) async =>
          streamed(200, sse([textChunk('目前'), textChunk('沒有')]));
      final events = await complete();
      expect(events.whereType<ModelText>().map((e) => e.delta), ['目前', '沒有']);
      final done = events.last as ModelDone;
      expect(done.message.text, '目前沒有');
      expect(done.message.toolCalls, isEmpty);
    });

    test('assembles a tool call sent in pieces', () async {
      Map<String, Object?> piece(Map<String, Object?> call) => {
        'choices': [
          {
            'delta': {
              'tool_calls': [call],
            },
          },
        ],
      };
      api.onStream = (_) async => streamed(
        200,
        sse([
          piece({
            'index': 0,
            'id': 'call_a',
            'function': {'name': 'eew', 'arguments': '{"a'},
          }),
          piece({
            'index': 0,
            'function': {'arguments': 't":1}'},
          }),
          piece({
            'index': 1,
            'id': 'call_b',
            'function': {'name': 'rts', 'arguments': '{}'},
          }),
          // A usage-only chunk carries no choices.
          {'choices': <Object>[], 'usage': <String, Object>{}},
        ]),
      );
      final done = (await complete()).last as ModelDone;
      final calls = done.message.toolCalls;
      expect(calls.map((c) => (c.id, c.name, c.arguments)), [
        ('call_a', 'eew', '{"at":1}'),
        ('call_b', 'rts', '{}'),
      ]);
    });

    test('tells apart calls that come without an index', () async {
      api.onStream = (_) async => streamed(
        200,
        sse([
          for (final id in ['x', 'y'])
            {
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'id': id,
                        'function': {
                          'name': 'eew',
                          'arguments': {'id': id},
                        },
                      },
                    ],
                  },
                },
              ],
            },
        ]),
      );
      final done = (await complete()).last as ModelDone;
      expect(done.message.toolCalls.map((c) => (c.id, c.arguments)), [
        ('x', '{"id":"x"}'),
        ('y', '{"id":"y"}'),
      ]);
    });

    test('reports reasoning as thinking, and hides a <think> block', () async {
      api.onStream = (_) async => streamed(
        200,
        sse([
          {
            'choices': [
              {
                'delta': {'reasoning_content': 'hmm'},
              },
            ],
          },
          textChunk('<thi'),
          textChunk('nk>plan</th'),
          textChunk('ink>\n\n答案'),
        ]),
      );
      final events = await complete();
      expect(events.whereType<ModelThinking>(), isNotEmpty);
      expect(events.whereType<ModelText>().map((e) => e.delta).join(), '答案');
      expect((events.last as ModelDone).message.text, '答案');
    });

    test(
      'reads a whole JSON answer from a service that does not stream',
      () async {
        api.onStream = (_) async => streamed(
          200,
          Stream.value(
            utf8.encode(
              jsonEncode({
                'choices': [
                  {
                    'message': {'role': 'assistant', 'content': '一次給完'},
                  },
                ],
              }),
            ),
          ),
          contentType: 'application/json',
        );
        final done = (await complete()).last as ModelDone;
        expect(done.message.text, '一次給完');
      },
    );
  });

  group('failures', () {
    Future<AiException> failure() async {
      try {
        await complete();
      } on AiException catch (e) {
        return e;
      }
      fail('no failure');
    }

    test(
      'an HTTP error carries the status and the service\'s reason',
      () async {
        api.onStream = (_) async => streamed(
          401,
          Stream.value(
            utf8.encode('{"error":{"message":"Incorrect API key provided"}}'),
          ),
          contentType: 'application/json',
        );
        final e = await failure();
        expect(e.kind, AiFailureKind.unauthorized);
        expect(e.status, 401);
        expect(e.detail, 'Incorrect API key provided');
      },
    );

    test('an error inside a 200 stream is still an error', () async {
      api.onStream = (_) async => streamed(
        200,
        sse([
          {
            'error': {'code': 429, 'message': 'Rate limit exceeded'},
          },
        ]),
      );
      final e = await failure();
      expect(e.kind, AiFailureKind.rateLimited);
      expect(e.detail, 'Rate limit exceeded');
    });

    test('a body that is not JSON is a bad response', () async {
      api.onStream = (_) async => streamed(200, sse(['<html>']));
      expect((await failure()).kind, AiFailureKind.badResponse);
    });

    test('a dropped connection is a network failure', () async {
      api.onStream = (request) async => throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
      expect((await failure()).kind, AiFailureKind.network);
    });
  });

  test('cancelling the stream cancels the request', () async {
    final hold = Completer<Response<ResponseBody>>();
    api.onStream = (_) => hold.future;
    final sub = OpenAiChatModel(api, _connection, 'k')
        .complete(messages: const [UserMessage('hi')], tools: const [])
        .listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    expect(api.seen.single.cancel!.isCancelled, isTrue);
  });

  group('encoding', () {
    test('an assistant tool call has null content and "{}" arguments', () {
      final wire = OpenAiChatModel.encodeMessage(
        const AssistantMessage(
          toolCalls: [ToolCall(id: 'c', name: 'eew', arguments: '')],
        ),
      );
      expect(wire['content'], isNull);
      expect(wire.containsKey('content'), isTrue);
      final call = (wire['tool_calls']! as List).single as Map;
      expect((call['function'] as Map)['arguments'], '{}');
    });

    test('a tool result names the call it answers', () {
      expect(
        OpenAiChatModel.encodeMessage(
          const ToolResultMessage(callId: 'c', name: 'eew', content: '[]'),
        ),
        {'role': 'tool', 'tool_call_id': 'c', 'content': '[]'},
      );
    });

    test('the schema keeps parameter names that look like keywords', () {
      final clean = OpenAiChatModel.sanitizeSchema({
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'additionalProperties': {'type': 'string'},
          'kind': {
            'type': ['string', 'null'],
            'enum': ['a', null],
          },
          'list': {
            'type': 'array',
            'items': {'type': 'object', 'additionalProperties': false},
          },
        },
      });
      expect(clean, {
        'type': 'object',
        'properties': {
          'additionalProperties': {'type': 'string'},
          'kind': {
            'type': 'string',
            'enum': ['a'],
          },
          'list': {
            'type': 'array',
            'items': {'type': 'object', 'properties': <String, Object?>{}},
          },
        },
      });
    });
  });
}
