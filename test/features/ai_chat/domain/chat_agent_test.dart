import 'dart:async';

import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/chat_agent.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeToolHost tools;
  late List<ChatMessage> history;

  setUp(() {
    tools = FakeToolHost();
    history = [const UserMessage('最近有地震嗎？')];
  });

  Stream<AgentEvent> run(ChatAgent agent) => agent.run(
    systemPrompt: (notes) => 'system ($notes)',
    history: history,
    record: history.add,
  );

  test('a plain answer streams its text and is recorded', () async {
    final model = FakeChatModel([says('沒有。')]);
    final events = await run(ChatAgent(model: model, tools: tools)).toList();

    expect(events.whereType<AgentText>().map((e) => e.delta), ['沒有。']);
    expect(history.last, isA<AssistantMessage>());
    expect((history.last as AssistantMessage).text, '沒有。');
    // The server's notes reach the system prompt, which leads the request.
    final first = model.requests.single.first as SystemMessage;
    expect(first.text, 'system (server notes)');
  });

  test('a tool call is run and its result sent back, in order', () async {
    final model = FakeChatModel([
      calls([
        const ToolCall(id: 'c1', name: 'eew', arguments: '{"at":1}'),
      ], text: '查一下。'),
      says('目前沒有速報。'),
    ]);
    final events = await run(ChatAgent(model: model, tools: tools)).toList();

    expect(tools.callsSeen.single.$1, 'eew');
    expect(tools.callsSeen.single.$2, {'at': 1});
    expect(events.whereType<AgentToolStarted>().single.name, 'eew');
    expect(events.whereType<AgentToolFinished>().single.ok, isTrue);
    // History: question, the call with its text, its result, the answer.
    expect(history.map((m) => m.runtimeType), [
      UserMessage,
      AssistantMessage,
      ToolResultMessage,
      AssistantMessage,
    ]);
    final call = history[1] as AssistantMessage;
    expect(call.text, '查一下。');
    expect(call.toolCalls.single.id, 'c1');
    final result = history[2] as ToolResultMessage;
    expect(result.callId, 'c1');
    expect(result.content, 'result of eew {"at":1}');
    // The second request carried the result.
    expect(model.requests[1].whereType<ToolResultMessage>(), hasLength(1));
  });

  test(
    'bad arguments and unknown tools go back to the model as errors',
    () async {
      final model = FakeChatModel([
        calls([
          const ToolCall(id: 'a', name: 'eew', arguments: '{not json'),
          const ToolCall(id: 'b', name: 'nope', arguments: '{}'),
          const ToolCall(id: 'c', name: 'eew', arguments: '[1]'),
          const ToolCall(id: 'd', name: 'eew', arguments: ''),
        ]),
        says('抱歉。'),
      ]);
      final events = await run(ChatAgent(model: model, tools: tools)).toList();

      // Only the empty-argument call reached the server, as `{}`.
      expect(tools.callsSeen.single.$1, 'eew');
      expect(tools.callsSeen.single.$2, isEmpty);
      final finished = events.whereType<AgentToolFinished>().toList();
      expect(finished.map((e) => e.ok), [false, false, false, true]);
      final results = history.whereType<ToolResultMessage>().toList();
      expect(results[0].content, contains('not a JSON object'));
      expect(results[1].content, contains('no tool named "nope"'));
    },
  );

  test('calls past the per-step limit are refused, not run', () async {
    final model = FakeChatModel([
      calls([
        for (var i = 0; i < 4; i++)
          ToolCall(id: 'c$i', name: 'eew', arguments: '{}'),
      ]),
      says('好。'),
    ]);
    await run(ChatAgent(model: model, tools: tools, maxCallsPerStep: 2))
        .toList();

    expect(tools.callsSeen, hasLength(2));
    final results = history.whereType<ToolResultMessage>().toList();
    expect(results, hasLength(4));
    expect(results[3].content, contains('at most 2 tool calls'));
  });

  test('a long result is cut, and says so', () async {
    tools.answer = (_, _) => ToolOutcome('x' * 50);
    final model = FakeChatModel([
      calls([const ToolCall(id: 'c', name: 'eew', arguments: '{}')]),
      says('好。'),
    ]);
    await run(ChatAgent(model: model, tools: tools, maxResultChars: 10))
        .toList();

    final result = history.whereType<ToolResultMessage>().single;
    expect(result.content, startsWith('xxxxxxxxxx\n[Cut at 10 characters.'));
  });

  test('a model that never stops calling tools is stopped', () async {
    final step = calls([const ToolCall(id: 'c', name: 'eew', arguments: '{}')]);
    final model = FakeChatModel([step, step, step]);
    await expectLater(
      run(ChatAgent(model: model, tools: tools, maxSteps: 3)),
      emitsThrough(
        emitsError(
          isA<AiException>().having(
            (e) => e.kind,
            'kind',
            AiFailureKind.tooManySteps,
          ),
        ),
      ),
    );
    expect(model.requests, hasLength(3));
    // Every call recorded has its answer: the history stays sendable.
    expect(
      history.whereType<AssistantMessage>().length,
      history.whereType<ToolResultMessage>().length,
    );
  });

  test('when the tools cannot be listed, nothing is asked', () async {
    tools.catalogError = const AiException(AiFailureKind.toolsUnavailable);
    final model = FakeChatModel([says('不該出現')]);
    await expectLater(
      run(ChatAgent(model: model, tools: tools)),
      emitsError(isA<AiException>()),
    );
    expect(model.requests, isEmpty);
    expect(history, hasLength(1));
  });

  test('a failure mid-answer keeps the text so far, once', () async {
    final model = FakeChatModel([
      fails(const AiException(AiFailureKind.server), text: '目前'),
    ]);
    final errors = <Object>[];
    final done = Completer<void>();
    run(ChatAgent(model: model, tools: tools))
        .listen((_) {}, onError: errors.add, onDone: done.complete);
    await done.future;

    expect(errors.single, isA<AiException>());
    expect(history, hasLength(2));
    expect((history.last as AssistantMessage).text, '目前');
  });

  test('a stream that ends without a message is a bad response', () async {
    final model = FakeChatModel([() => const Stream.empty()]);
    await expectLater(
      run(ChatAgent(model: model, tools: tools)),
      emitsError(
        isA<AiException>().having(
          (e) => e.kind,
          'kind',
          AiFailureKind.badResponse,
        ),
      ),
    );
  });

  group('cancelling', () {
    test('aborts a silent model at once and records the text so far', () async {
      final silent = StreamController<ModelEvent>();
      final model = FakeChatModel([() => silent.stream]);
      final texts = <String>[];
      final sub = run(ChatAgent(model: model, tools: tools)).listen((e) {
        if (e is AgentText) texts.add(e.delta);
      });
      await pumpEventQueue();
      silent.add(const ModelText('正在'));
      await pumpEventQueue();
      expect(texts, ['正在']);

      // The model says nothing more; cancel must not wait for it.
      await sub.cancel();
      expect(model.cancelled, 1);
      // Recorded by the time cancel returned, exactly once.
      expect(history, hasLength(2));
      expect((history.last as AssistantMessage).text, '正在');

      await pumpEventQueue();
      expect(history, hasLength(2));
      await silent.close();
    });

    test('drops tool results that arrive after it', () async {
      final release = Completer<ToolOutcome>();
      tools.answer = (_, _) => release.future;
      final model = FakeChatModel([
        calls([
          const ToolCall(id: 'c', name: 'eew', arguments: '{}'),
        ], text: '查一下'),
      ]);
      final started = Completer<void>();
      final sub = run(ChatAgent(model: model, tools: tools)).listen((e) {
        if (e is AgentToolStarted) started.complete();
      });
      await started.future;

      await sub.cancel();
      release.complete(const ToolOutcome('late'));
      await pumpEventQueue();

      // The call has no answer, so it is not in the history; its text is.
      expect(history.map((m) => m.runtimeType), [
        UserMessage,
        AssistantMessage,
      ]);
      final said = history.last as AssistantMessage;
      expect(said.text, '查一下');
      expect(said.toolCalls, isEmpty);
    });

    test('records nothing when nothing was said', () async {
      final silent = StreamController<ModelEvent>();
      final model = FakeChatModel([() => silent.stream]);
      final sub = run(ChatAgent(model: model, tools: tools)).listen((_) {});
      await pumpEventQueue();
      await sub.cancel();
      await pumpEventQueue();
      expect(history, hasLength(1));
      await silent.close();
    });
  });

  test('results of earlier questions are compacted, the latest kept', () {
    final compacted = ChatAgent.compact([
      const UserMessage('一'),
      const AssistantMessage(
        toolCalls: [ToolCall(id: 'a', name: 'eew', arguments: '{}')],
      ),
      const ToolResultMessage(callId: 'a', name: 'eew', content: 'old'),
      const AssistantMessage(text: '答一'),
      const UserMessage('二'),
      const AssistantMessage(
        toolCalls: [ToolCall(id: 'b', name: 'eew', arguments: '{}')],
      ),
      const ToolResultMessage(callId: 'b', name: 'eew', content: 'new'),
    ]);
    final results = compacted.whereType<ToolResultMessage>().toList();
    expect(results[0].callId, 'a');
    expect(results[0].content, contains('Earlier result omitted'));
    expect(results[1].content, 'new');
  });
}
