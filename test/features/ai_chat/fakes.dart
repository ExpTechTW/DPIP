import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/platform/secret_store.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';

class FakeSecretStore implements SecretStore {
  final Map<SecretKey, String> values = {};
  bool refuseWrites = false;

  @override
  Future<String?> read(SecretKey key) async => values[key];

  @override
  Future<void> write(SecretKey key, String value) async {
    if (refuseWrites) throw StateError('refused');
    values[key] = value;
  }

  @override
  Future<void> delete(SecretKey key) async => values.remove(key);
}

/// One request [FakeApi] saw.
final class SeenRequest {
  SeenRequest(this.method, this.url, this.headers, this.data, this.cancel);

  final String method;
  final String url;
  final Map<String, dynamic> headers;
  final Object? data;
  final CancelToken? cancel;

  Map<String, Object?> get json =>
      jsonDecode(data! as String) as Map<String, Object?>;
}

/// An [ApiClient] answering from scripted handlers; anything else throws.
class FakeApi implements ApiClient {
  final List<SeenRequest> seen = [];

  /// Answers [streamAbsolute].
  Future<Response<ResponseBody>> Function(SeenRequest request)? onStream;

  /// Answers [request] (the region-aware call the MCP host makes).
  Future<Response<dynamic>> Function(ApiTier tier, SeenRequest request)?
  onRequest;

  @override
  Future<Response<ResponseBody>> streamAbsolute(
    String url, {
    String method = 'POST',
    Object? data,
    Map<String, dynamic>? headers,
    Duration idleTimeout = Duration.zero,
    CancelToken? cancelToken,
  }) {
    final request = SeenRequest(method, url, {...?headers}, data, cancelToken);
    seen.add(request);
    return onStream!(request);
  }

  @override
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) {
    final request = SeenRequest(
      method,
      path,
      {...?options?.headers},
      data,
      cancelToken,
    );
    seen.add(request);
    return onRequest!(tier, request);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A streamed HTTP answer, as `streamAbsolute` returns it.
Response<ResponseBody> streamed(
  int status,
  Stream<List<int>> body, {
  String contentType = 'text/event-stream',
}) => Response<ResponseBody>(
  requestOptions: RequestOptions(),
  statusCode: status,
  headers: Headers.fromMap({
    Headers.contentTypeHeader: [contentType],
  }),
  data: ResponseBody(body.map(Uint8List.fromList), status),
);

/// An event-stream body of one `data:` frame per item, then `[DONE]`.
Stream<List<int>> sse(List<Object> frames, {bool done = true}) =>
    Stream.fromIterable([
      for (final frame in frames)
        utf8.encode('data: ${frame is String ? frame : jsonEncode(frame)}\n\n'),
      if (done) utf8.encode('data: [DONE]\n\n'),
    ]);

/// A content delta chunk.
Map<String, Object?> textChunk(String text) => {
  'choices': [
    {
      'delta': {'content': text},
    },
  ],
};

/// A [ChatModel] answering from a script, one entry per request.
class FakeChatModel implements ChatModel {
  FakeChatModel(this.script);

  /// Each step's events; a step that is a [Completer]'s future never ends on
  /// its own (for cancellation tests).
  final List<Stream<ModelEvent> Function()> script;
  final List<List<ChatMessage>> requests = [];
  int cancelled = 0;

  @override
  Stream<ModelEvent> complete({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
  }) {
    requests.add(List.of(messages));
    final step = script[requests.length - 1]();
    late final StreamController<ModelEvent> out;
    StreamSubscription<ModelEvent>? sub;
    out = StreamController<ModelEvent>(
      onListen: () {
        sub = step.listen(out.add, onError: out.addError, onDone: out.close);
      },
      // Not returning the inner cancel: once the step has ended it is the
      // root zone's completed future, and a widget test's fake clock would
      // then hold this stream's done event until the test is over.
      onCancel: () {
        cancelled++;
        unawaited(sub?.cancel());
      },
    );
    return out.stream;
  }
}

/// A step that writes [text] and finishes with it.
Stream<ModelEvent> Function() says(String text) =>
    () => Stream.fromIterable([
      ModelText(text),
      ModelDone(AssistantMessage(text: text)),
    ]);

/// A step that calls tools.
Stream<ModelEvent> Function() calls(List<ToolCall> calls, {String text = ''}) =>
    () => Stream.fromIterable([
      if (text.isNotEmpty) ModelText(text),
      ModelDone(AssistantMessage(text: text, toolCalls: calls)),
    ]);

/// A step that fails with [failure] after [text].
Stream<ModelEvent> Function() fails(AiException failure, {String text = ''}) =>
    () async* {
      if (text.isNotEmpty) yield ModelText(text);
      throw failure;
    };

class FakeToolHost implements ToolHost {
  FakeToolHost({
    this.tools = const ['eew', 'weather_forecast', 'earthquake_reports'],
    this.instructions = 'server notes',
  });

  final List<String> tools;
  final String? instructions;
  final List<(String, Map<String, Object?>)> callsSeen = [];
  Object? catalogError;

  /// Answers by tool name; the default echoes the arguments.
  FutureOr<ToolOutcome> Function(String name, Map<String, Object?> args)?
  answer;

  @override
  Future<ToolCatalog> catalog() async {
    if (catalogError != null) throw catalogError!;
    return ToolCatalog(
      tools: [
        for (final name in tools)
          ToolSpec(
            name: name,
            description: 'tool $name',
            parameters: const {'type': 'object'},
          ),
      ],
      instructions: instructions,
    );
  }

  @override
  Future<ToolOutcome> call(String name, Map<String, Object?> arguments) async {
    callsSeen.add((name, arguments));
    return await answer?.call(name, arguments) ??
        ToolOutcome('result of $name ${jsonEncode(arguments)}');
  }
}
