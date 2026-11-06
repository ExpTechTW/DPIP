/// Why an AI chat request failed, in the terms the page explains it in.
library;

enum AiFailureKind {
  /// 401 / 403: the key is wrong, expired, or lacks access to the model.
  unauthorized,

  /// 404: the URL is not an OpenAI-compatible API, or the model does not
  /// exist there.
  notFound,

  /// 429: the service's rate limit or quota.
  rateLimited,

  /// Another 4xx: the service refused the request; its own [AiException.detail]
  /// says why (often a model that cannot call tools).
  rejected,

  /// 5xx from the AI service.
  server,

  /// No connection, or the connection dropped.
  network,

  /// The service went quiet for longer than the chat waits.
  timeout,

  /// The service answered with something that is not a chat completion.
  badResponse,

  /// The DPIP data tools could not be listed.
  toolsUnavailable,

  /// The model kept calling tools past the per-question limit.
  tooManySteps,
}

final class AiException implements Exception {
  const AiException(this.kind, {this.status, this.detail});

  final AiFailureKind kind;

  /// The HTTP status, when there was one.
  final int? status;

  /// The service's own explanation, verbatim and untranslated (it is the
  /// service's text, not the app's), trimmed to a readable length.
  final String? detail;

  @override
  String toString() =>
      'AiException(${kind.name}${status == null ? '' : ', HTTP $status'})';
}
