/// One AI conversation, held in memory only.
///
/// Nothing here is persisted: the conversation ends with the app process (the
/// explanation page promises as much). The page shows [entries]; the AI
/// service is sent [ChatMessage]s, which carry the exact tool calls and
/// results the page only summarises.
library;

import 'dart:async';
import 'dart:collection';

import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_settings_repository.dart';
import 'package:dpip/features/ai_chat/domain/chat_agent.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/system_prompt.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';
import 'package:flutter/foundation.dart';

sealed class ChatEntry {
  const ChatEntry();
}

final class QuestionEntry extends ChatEntry {
  const QuestionEntry(this.text);

  final String text;
}

enum ToolState { running, ok, failed }

final class ToolActivity {
  ToolActivity(this.callId, this.name);

  final String callId;
  final String name;
  ToolState state = ToolState.running;
}

/// The answer to one question, filled in as it streams.
final class AnswerEntry extends ChatEntry {
  AnswerEntry(this.question);

  /// What it answers — kept so a failed answer can be asked again.
  final String question;

  final StringBuffer _text = StringBuffer();
  final List<ToolActivity> tools = [];

  String get text => _text.toString();

  /// The model is reasoning and has not written anything yet.
  bool thinking = false;

  bool done = false;

  /// Stopped by the user before it finished.
  bool stopped = false;

  AiException? failure;
}

class AiChatController extends ChangeNotifier {
  AiChatController({
    required this._settings,
    required this._models,
    required this._tools,
    required this._places,
    required this._taipeiNow,
  });

  final AiSettingsRepository _settings;
  final ChatModelFactory _models;
  final ToolHost _tools;
  final List<PromptPlace> Function() _places;
  final DateTime Function() _taipeiNow;

  final List<ChatEntry> _entries = [];
  final List<ChatMessage> _history = [];

  StreamSubscription<AgentEvent>? _turn;
  AnswerEntry? _answer;

  /// Bumped by [stop] and [clear], so a turn still awaiting its key cannot
  /// start after it was called off.
  int _generation = 0;

  Timer? _coalesce;

  List<ChatEntry> get entries => UnmodifiableListView(_entries);

  bool get isEmpty => _entries.isEmpty;

  /// A question is being answered.
  bool get busy => _answer != null;

  /// Asks [question]. [language] (the language's own name) and [localeTag]
  /// set the reply language.
  Future<void> send(
    String question, {
    required String language,
    required String localeTag,
  }) async {
    final text = question.trim();
    final connection = _settings.connection;
    if (text.isEmpty || busy || !connection.isComplete) return;

    final generation = ++_generation;
    final answer = AnswerEntry(text);
    final asked = UserMessage(text);
    _entries
      ..add(QuestionEntry(text))
      ..add(answer);
    _history.add(asked);
    _answer = answer;
    notifyListeners();

    final key = await _settings.apiKey();
    if (generation != _generation) return;

    final agent = ChatAgent(model: _models(connection, key), tools: _tools);
    _turn = agent
        .run(
          systemPrompt: (notes) => buildSystemPrompt(
            taipeiNow: _taipeiNow(),
            language: language,
            localeTag: localeTag,
            places: _places(),
            serverNotes: notes,
          ),
          history: _history,
          record: _history.add,
        )
        .listen(
          (event) => _apply(answer, event),
          onError: (Object error) {
            answer.failure = error is AiException
                ? error
                : const AiException(AiFailureKind.network);
            _finish(answer, asked);
          },
          onDone: () => _finish(answer, asked),
          cancelOnError: true,
        );
  }

  /// Asks a failed question again.
  Future<void> retry(
    AnswerEntry failed, {
    required String language,
    required String localeTag,
  }) async {
    if (busy) return;
    final index = _entries.indexOf(failed);
    // The question above it goes too: send() adds both back.
    if (index > 0 && _entries[index - 1] is QuestionEntry) {
      _entries.removeRange(index - 1, index + 1);
    } else if (index >= 0) {
      _entries.removeAt(index);
    }
    await send(failed.question, language: language, localeTag: localeTag);
  }

  /// Stops the answer in progress, keeping what it has said.
  void stop() {
    final answer = _answer;
    if (answer == null) return;
    _generation++;
    answer.stopped = true;
    // Cancelling records the text so far into the history synchronously.
    unawaited(_turn?.cancel());
    _finish(answer, null);
  }

  /// Starts over: an empty page and an empty history.
  void clear() {
    if (busy) stop();
    _generation++;
    _entries.clear();
    _history.clear();
    notifyListeners();
  }

  void _apply(AnswerEntry answer, AgentEvent event) {
    switch (event) {
      case AgentText(:final delta):
        answer
          .._text.write(delta)
          ..thinking = false;
        // Text arrives a token at a time; one rebuild per few tokens is as
        // smooth to read and far cheaper to lay out on a slow phone.
        _coalesce ??= Timer(const Duration(milliseconds: 80), _flush);
        return;
      case AgentThinking():
        if (answer.thinking || answer.text.isNotEmpty) return;
        answer.thinking = true;
      case AgentToolStarted(:final callId, :final name):
        answer
          ..thinking = false
          ..tools.add(ToolActivity(callId, name));
      case AgentToolFinished(:final callId, :final ok):
        for (final tool in answer.tools) {
          if (tool.callId == callId) {
            tool.state = ok ? ToolState.ok : ToolState.failed;
          }
        }
    }
    _flush();
  }

  /// Ends [answer]'s turn. [asked] is its question, when the turn ended by
  /// itself: one that left no answer in the history is taken back out, so a
  /// retry or the next question does not follow an unanswered one (some
  /// services reject two user messages in a row).
  void _finish(AnswerEntry answer, UserMessage? asked) {
    if (!identical(_answer, answer)) return;
    answer
      ..done = true
      ..thinking = false;
    _answer = null;
    _turn = null;
    if (_history.isNotEmpty && identical(_history.last, asked)) {
      _history.removeLast();
    }
    if (asked == null && _history.isNotEmpty && _history.last is UserMessage) {
      _history.removeLast();
    }
    _flush();
  }

  void _flush() {
    _coalesce?.cancel();
    _coalesce = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_turn?.cancel());
    _coalesce?.cancel();
    super.dispose();
  }
}
