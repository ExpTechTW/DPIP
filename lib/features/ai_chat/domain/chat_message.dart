/// The conversation as the AI service sees it: what is sent on every turn.
///
/// Kept apart from what the page shows. The page shows tool activity as a
/// line of status; the service needs the exact call it made and the exact
/// answer it got, in order, or the next request is rejected.
library;

sealed class ChatMessage {
  const ChatMessage();
}

/// The instructions that open every request. Rebuilt per turn (it carries the
/// time), never stored in the history.
final class SystemMessage extends ChatMessage {
  const SystemMessage(this.text);

  final String text;
}

final class UserMessage extends ChatMessage {
  const UserMessage(this.text);

  final String text;
}

/// What the model answered: text, tool calls, or both.
final class AssistantMessage extends ChatMessage {
  const AssistantMessage({this.text = '', this.toolCalls = const []});

  final String text;
  final List<ToolCall> toolCalls;
}

/// The answer to one [ToolCall], matched to it by [callId].
final class ToolResultMessage extends ChatMessage {
  const ToolResultMessage({
    required this.callId,
    required this.name,
    required this.content,
  });

  final String callId;
  final String name;
  final String content;
}

/// One tool call as the model wrote it.
final class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;

  /// The arguments as the JSON text the model produced — kept verbatim,
  /// because that is what has to be sent back with the call.
  final String arguments;
}
