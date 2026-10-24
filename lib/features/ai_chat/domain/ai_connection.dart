/// The user's own AI service, as the AI chat talks to it.
library;

import 'package:dpip/features/ai_chat/domain/chat_model.dart';

/// An OpenAI-compatible endpoint and the model to ask there. The API key is
/// not part of it: the key never sits in a settings value, only in the
/// platform's key storage, read at the moment of a request.
final class AiConnection {
  const AiConnection({required this.baseUrl, required this.model});

  static const AiConnection empty = AiConnection(baseUrl: '', model: '');

  /// The API root, without a trailing slash: `…/chat/completions` and
  /// `…/models` are appended to it.
  final String baseUrl;
  final String model;

  bool get isComplete => baseUrl.isNotEmpty && model.isNotEmpty;
}

/// Builds the model client for a connection; [apiKey] may be null for a
/// service that needs none.
typedef ChatModelFactory = ChatModel Function(
  AiConnection connection,
  String? apiKey,
);

/// A well-known service, offered as a one-tap base URL.
final class AiPreset {
  const AiPreset(this.name, this.baseUrl);

  /// The service's own name — a proper noun, the same in every language.
  final String name;
  final String baseUrl;
}

/// Services with an OpenAI-compatible chat API that supports tool calls.
const List<AiPreset> aiPresets = [
  AiPreset('OpenAI', 'https://api.openai.com/v1'),
  AiPreset(
    'Google Gemini',
    'https://generativelanguage.googleapis.com/v1beta/openai',
  ),
  AiPreset('Anthropic', 'https://api.anthropic.com/v1'),
  AiPreset('OpenRouter', 'https://openrouter.ai/api/v1'),
  AiPreset('Groq', 'https://api.groq.com/openai/v1'),
];

enum BaseUrlProblem {
  empty,
  invalid,

  /// Plain `http://` to anything but this phone. Android refuses cleartext
  /// to other hosts outright, and a key sent in the clear is a key given
  /// away, so it is caught here with a reason rather than failing later
  /// with an opaque connection error.
  insecure,
}

/// Cleans up what the user typed or pasted: surrounding space, trailing
/// slashes, and a pasted full `/chat/completions` endpoint all reduce to the
/// API root.
({String? url, BaseUrlProblem? problem}) normalizeBaseUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return (url: null, problem: BaseUrlProblem.empty);
  text = text.replaceFirst(RegExp(r'/+$'), '');
  text = text.replaceFirst(RegExp(r'/chat/completions$'), '');
  text = text.replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty) {
    return (url: null, problem: BaseUrlProblem.invalid);
  }
  if (uri.scheme == 'http' &&
      !(uri.host == 'localhost' || uri.host == '127.0.0.1')) {
    return (url: null, problem: BaseUrlProblem.insecure);
  }
  return (url: text, problem: null);
}
