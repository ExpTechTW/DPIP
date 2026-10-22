/// A chat-completion service, streamed.
library;

import 'package:dpip/features/ai_chat/domain/chat_message.dart';
import 'package:dpip/features/ai_chat/domain/tool_host.dart';

sealed class ModelEvent {
  const ModelEvent();
}

/// More of the answer's text, as it arrives.
final class ModelText extends ModelEvent {
  const ModelText(this.delta);

  final String delta;
}

/// The model is reasoning before it answers. Carries no text: the reasoning
/// is not shown, only that something is happening.
final class ModelThinking extends ModelEvent {
  const ModelThinking();
}

/// The completed message — the last event of every successful stream.
final class ModelDone extends ModelEvent {
  const ModelDone(this.message);

  final AssistantMessage message;
}

abstract class ChatModel {
  /// Streams one completion over [messages], offering [tools].
  ///
  /// Ends with a [ModelDone]; fails with an `AiException`. Cancelling the
  /// subscription aborts the request.
  Stream<ModelEvent> complete({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
  });
}
