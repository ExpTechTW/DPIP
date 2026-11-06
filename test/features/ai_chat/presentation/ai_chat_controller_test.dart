import 'dart:async';

import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/ai_settings_repository.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/system_prompt.dart';
import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

class FakeSettings implements AiSettingsRepository {
  FakeSettings({
    this.connection = const AiConnection(
      baseUrl: 'https://ai.example/v1',
      model: 'm',
    ),
    this.key = 'sk',
  });

  @override
  AiConnection connection;
  String? key;
  bool seen = false;

  @override
  bool get introSeen => seen;

  @override
  Future<void> markIntroSeen() async => seen = true;

  @override
  Future<String?> apiKey() async => key;

  @override
  Future<void> save(AiConnection connection, {String? apiKey}) async {
    this.connection = connection;
    if (apiKey != null) key = apiKey.isEmpty ? null : apiKey;
  }

  @override
  Future<void> forget() async {
    connection = AiConnection.empty;
    key = null;
  }

  @override
  Future<List<String>> listModels(String baseUrl, String? apiKey) async => [];
}

void main() {
  late FakeSettings settings;
  late FakeToolHost tools;
  late List<FakeChatModel> built;
  late List<String?> keys;
  late List<List<Stream<ModelEvent> Function()>> scripts;

  AiChatController controller() => AiChatController(
    settings: settings,
    models: (connection, key) {
      keys.add(key);
      final model = FakeChatModel(scripts.removeAt(0));
      built.add(model);
      return model;
    },
    tools: tools,
    places: () => const [
      PromptPlace(name: '臺北市 中正區', code: '100', current: true),
    ],
    taipeiNow: () => DateTime.utc(2026, 10, 22, 6),
  );

  setUp(() {
    settings = FakeSettings();
    tools = FakeToolHost();
    built = [];
    keys = [];
    scripts = [];
  });

  Future<void> ask(AiChatController chat, String text) async {
    await chat.send(text, language: '繁體中文', localeTag: 'zh-TW');
    await pumpEventQueue();
  }

  test('a question and its answer, with the tools it used', () async {
    scripts.add([
      calls([const ToolCall(id: 'c', name: 'eew', arguments: '{}')]),
      says('目前沒有速報。'),
    ]);
    final chat = controller();
    await ask(chat, '  有速報嗎？ ');

    expect(chat.busy, isFalse);
    expect(chat.entries, hasLength(2));
    expect((chat.entries[0] as QuestionEntry).text, '有速報嗎？');
    final answer = chat.entries[1] as AnswerEntry;
    expect(answer.done, isTrue);
    expect(answer.text, '目前沒有速報。');
    expect(answer.tools.single.name, 'eew');
    expect(answer.tools.single.state, ToolState.ok);
    expect(keys, ['sk']);

    // The prompt carried the time, the language and the place.
    final system = built.single.requests.first.first as SystemMessage;
    expect(system.text, contains('2026-10-22'));
    expect(system.text, contains('繁體中文 (zh-TW)'));
    expect(system.text, contains('臺北市 中正區 (100)'));
  });

  test('a follow-up question is asked with the earlier turn', () async {
    scripts
      ..add([says('一')])
      ..add([says('二')]);
    final chat = controller();
    await ask(chat, '第一題');
    await ask(chat, '第二題');
    final second = built[1].requests.single;
    expect(second.whereType<UserMessage>().map((m) => m.text), ['第一題', '第二題']);
    expect(second.whereType<AssistantMessage>().single.text, '一');
  });

  test('a failed question can be asked again, without a duplicate', () async {
    scripts
      ..add([fails(const AiException(AiFailureKind.unauthorized, status: 401))])
      ..add([says('好了')]);
    final chat = controller();
    await ask(chat, '有颱風嗎？');
    final failed = chat.entries[1] as AnswerEntry;
    expect(failed.failure?.kind, AiFailureKind.unauthorized);

    await chat.retry(failed, language: '繁體中文', localeTag: 'zh-TW');
    await pumpEventQueue();
    expect(chat.entries, hasLength(2));
    expect((chat.entries[1] as AnswerEntry).text, '好了');
    // The unanswered first attempt is not in what was sent.
    expect(
      built[1].requests.single.whereType<UserMessage>().map((m) => m.text),
      ['有颱風嗎？'],
    );
  });

  test('stop keeps what was said and frees the conversation', () async {
    final silent = StreamController<ModelEvent>();
    scripts
      ..add([() => silent.stream])
      ..add([says('下一題')]);
    final chat = controller();
    await ask(chat, '慢慢說');
    silent.add(const ModelText('這是'));
    await pumpEventQueue();
    expect(chat.busy, isTrue);

    chat.stop();
    expect(chat.busy, isFalse);
    final answer = chat.entries[1] as AnswerEntry;
    expect(answer.stopped, isTrue);
    expect(answer.done, isTrue);

    await ask(chat, '下一個');
    final sent = built[1].requests.single;
    expect(sent.whereType<AssistantMessage>().single.text, '這是');
    await silent.close();
  });

  test('stop before anything was said leaves no question behind', () async {
    final silent = StreamController<ModelEvent>();
    scripts
      ..add([() => silent.stream])
      ..add([says('好')]);
    final chat = controller();
    await ask(chat, '第一題');
    chat.stop();
    await ask(chat, '第二題');
    expect(
      built[1].requests.single.whereType<UserMessage>().map((m) => m.text),
      ['第二題'],
    );
    await silent.close();
  });

  test('clear starts over', () async {
    scripts
      ..add([says('一')])
      ..add([says('二')]);
    final chat = controller();
    await ask(chat, '第一題');
    chat.clear();
    expect(chat.isEmpty, isTrue);
    await ask(chat, '第二題');
    expect(built[1].requests.single.whereType<UserMessage>(), hasLength(1));
  });

  test('nothing is sent without a complete setup', () async {
    settings.connection = AiConnection.empty;
    final chat = controller();
    await ask(chat, '有地震嗎？');
    expect(chat.isEmpty, isTrue);
    expect(built, isEmpty);
  });
}
