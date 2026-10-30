/// Runs one question: model, tools, model again — until the model answers.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/chat_model.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';

sealed class AgentEvent {
  const AgentEvent();
}

/// More of the answer's text.
final class AgentText extends AgentEvent {
  const AgentText(this.delta);

  final String delta;
}

/// The model is reasoning before it answers.
final class AgentThinking extends AgentEvent {
  const AgentThinking();
}

/// A tool call went out.
final class AgentToolStarted extends AgentEvent {
  const AgentToolStarted(this.callId, this.name);

  final String callId;
  final String name;
}

/// A tool call came back.
final class AgentToolFinished extends AgentEvent {
  const AgentToolFinished(this.callId, this.name, {required this.ok});

  final String callId;
  final String name;
  final bool ok;
}

class ChatAgent {
  ChatAgent({
    required this.model,
    required this.tools,
    this.maxSteps = 8,
    this.maxCallsPerStep = 6,
    this.maxResultChars = 16000,
  });

  final ChatModel model;
  final ToolHost tools;

  /// Model requests per question. Each step that calls tools costs the user
  /// a request to their AI service and the DPIP server a query per call, so
  /// a model stuck calling tools in a loop is stopped rather than indulged.
  final int maxSteps;

  /// Tool calls honoured from a single step; the rest are answered with an
  /// error telling the model to ask for fewer.
  final int maxCallsPerStep;

  /// A tool result longer than this is cut, with a note saying so. A year of
  /// earthquake reports would otherwise fill a small model's whole context.
  final int maxResultChars;

  /// Answers the last [UserMessage] in [history].
  ///
  /// Every message the turn adds is handed to [record] as it becomes final,
  /// so the caller's history stays valid whenever the stream stops: an
  /// assistant tool call is recorded only together with its results (a call
  /// with no answer makes the next request invalid), and text cut off by a
  /// cancellation is still recorded, so a follow-up question has it.
  ///
  /// [systemPrompt] receives the tool server's usage notes. Fails with an
  /// [AiException].
  ///
  /// Cancelling the subscription aborts the model request *at once* — not at
  /// the model's next word, which while it thinks may be a minute away. The
  /// history is final by the time `cancel` returns: the text so far is
  /// recorded, tool calls already sent finish on their own and are dropped,
  /// and nothing the old turn does later can land after a new question.
  Stream<AgentEvent> run({
    required String Function(String? serverNotes) systemPrompt,
    required List<ChatMessage> history,
    required void Function(ChatMessage message) record,
  }) {
    late final StreamController<AgentEvent> out;
    StreamSubscription<ModelEvent>? inner;
    Completer<AssistantMessage?>? step;
    var cancelled = false;
    // This step's text that is not in the history yet — what a cancellation
    // records, there and then.
    var unsaid = StringBuffer();

    void say(ChatMessage message) {
      if (!cancelled) record(message);
    }

    // Records [unsaid] once. Also reached from onCancel after a normal end
    // (a closed controller calls it too), so it must clear what it records.
    void sayUnsaid() {
      if (unsaid.isNotEmpty) record(AssistantMessage(text: unsaid.toString()));
      unsaid = StringBuffer();
    }

    Future<void> body() async {
      final catalog = await tools.catalog();
      if (cancelled) return;
      final system = SystemMessage(systemPrompt(catalog.instructions));
      final names = {for (final tool in catalog.tools) tool.name};
      for (var i = 0; i < maxSteps; i++) {
        unsaid = StringBuffer();
        AssistantMessage? answer;
        final done = step = Completer<AssistantMessage?>();
        inner = model
            .complete(
              messages: [system, ...compact(history)],
              tools: catalog.tools,
            )
            .listen(
              (event) {
                switch (event) {
                  case ModelText(:final delta):
                    unsaid.write(delta);
                    out.add(AgentText(delta));
                  case ModelThinking():
                    out.add(const AgentThinking());
                  case ModelDone(:final message):
                    answer = message;
                }
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!done.isCompleted) done.completeError(error, stackTrace);
              },
              onDone: () {
                if (!done.isCompleted) done.complete(answer);
              },
              cancelOnError: true,
            );
        final AssistantMessage? message;
        try {
          message = await done.future;
        } catch (_) {
          if (!cancelled) sayUnsaid();
          rethrow;
        } finally {
          inner = null;
          step = null;
        }
        if (cancelled) return;
        if (message == null) {
          sayUnsaid();
          throw const AiException(AiFailureKind.badResponse);
        }
        if (message.toolCalls.isEmpty) {
          unsaid = StringBuffer();
          say(message);
          return;
        }

        final calls = message.toolCalls;
        for (final call in calls) {
          out.add(AgentToolStarted(call.id, call.name));
        }
        final outcomes = await Future.wait([
          for (var c = 0; c < calls.length; c++)
            c < maxCallsPerStep
                ? _invoke(calls[c], names)
                : Future.value(
                    ToolOutcome(
                      'Not run: at most $maxCallsPerStep tool calls are '
                      'answered per step. Ask again with fewer.',
                      isError: true,
                    ),
                  ),
        ]);
        if (cancelled) return;
        unsaid = StringBuffer();
        say(message);
        for (var c = 0; c < calls.length; c++) {
          say(
            ToolResultMessage(
              callId: calls[c].id,
              name: calls[c].name,
              content: outcomes[c].content,
            ),
          );
        }
        for (var c = 0; c < calls.length; c++) {
          out.add(
            AgentToolFinished(
              calls[c].id,
              calls[c].name,
              ok: !outcomes[c].isError,
            ),
          );
        }
      }
      throw const AiException(AiFailureKind.tooManySteps);
    }

    out = StreamController<AgentEvent>(
      onListen: () {
        body()
            .catchError((Object error, StackTrace stackTrace) {
              if (!cancelled) out.addError(error, stackTrace);
            })
            .whenComplete(() {
              if (!out.isClosed) unawaited(out.close());
            });
      },
      onCancel: () {
        // Synchronously, so the history is final when cancel returns: what
        // was said so far goes in (without a tool call that has no answer),
        // and nothing more can follow it.
        if (!cancelled) sayUnsaid();
        cancelled = true;
        final pending = inner;
        inner = null;
        final waiting = step;
        if (waiting != null && !waiting.isCompleted) waiting.complete(null);
        return pending?.cancel();
      },
    );
    return out.stream;
  }

  Future<ToolOutcome> _invoke(ToolCall call, Set<String> names) async {
    if (!names.contains(call.name)) {
      return ToolOutcome(
        'There is no tool named "${call.name}".',
        isError: true,
      );
    }
    final Map<String, Object?> arguments;
    try {
      final text = call.arguments.trim();
      final decoded = text.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(text);
      if (decoded is! Map) throw const FormatException();
      arguments = Map<String, Object?>.from(decoded);
    } on FormatException {
      return const ToolOutcome(
        'The arguments were not a JSON object.',
        isError: true,
      );
    }
    final ToolOutcome outcome;
    try {
      outcome = await tools.call(call.name, arguments);
    } catch (_) {
      return const ToolOutcome(
        'The data server could not be reached.',
        isError: true,
      );
    }
    if (outcome.content.length <= maxResultChars) return outcome;
    return ToolOutcome(
      '${outcome.content.substring(0, maxResultChars)}\n'
      '[Cut at $maxResultChars characters. Narrow the query (a smaller limit, '
      'a date range, a place) for the rest.]',
      isError: outcome.isError,
    );
  }

  /// [history] with the results of tools called for *earlier* questions
  /// replaced by a note. They have been answered already, and a long
  /// conversation would otherwise resend every report it ever looked up —
  /// past a small model's context, and paid for again each turn.
  static List<ChatMessage> compact(List<ChatMessage> history) {
    final lastQuestion = history.lastIndexWhere((m) => m is UserMessage);
    return [
      for (var i = 0; i < history.length; i++)
        switch (history[i]) {
          final ToolResultMessage result when i < lastQuestion =>
            ToolResultMessage(
              callId: result.callId,
              name: result.name,
              content:
                  '[Earlier result omitted; call the tool again if it '
                  'is needed.]',
            ),
          final message => message,
        },
    ];
  }
}
