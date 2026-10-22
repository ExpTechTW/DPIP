/// HTTP plumbing shared by the AI service's calls: reading a body, and turning
/// its failures into [AiException]s.
///
/// Nothing here logs a URL, a key or a request body: the log can leave the
/// phone in a diagnostics report, and the page promises the setup does not.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';

/// [body] as text, reading at most [limit] bytes of it.
Future<String> readText(Stream<Uint8List> body, int limit) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in body) {
    bytes.add(chunk);
    if (bytes.length >= limit) break;
  }
  return utf8.decode(bytes.takeBytes(), allowMalformed: true);
}

/// The failure for an HTTP error [status], with the service's explanation
/// pulled out of [body] when it has one.
AiException aiExceptionForStatus(int status, String body) {
  final kind = switch (status) {
    401 || 403 => AiFailureKind.unauthorized,
    404 => AiFailureKind.notFound,
    429 => AiFailureKind.rateLimited,
    408 => AiFailureKind.timeout,
    >= 500 => AiFailureKind.server,
    _ => AiFailureKind.rejected,
  };
  return AiException(kind, status: status, detail: errorDetail(body));
}

/// The failure for a request that did not get an HTTP answer, or null for a
/// cancellation (which is not a failure: the user pressed stop).
AiException? aiExceptionForDio(DioException error) => switch (error.type) {
  DioExceptionType.cancel => null,
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout => const AiException(AiFailureKind.timeout),
  DioExceptionType.badResponse => aiExceptionForStatus(
    error.response?.statusCode ?? 0,
    switch (error.response?.data) {
      final String text => text,
      final Object? data => data == null ? '' : _tryEncode(data),
    },
  ),
  _ => const AiException(AiFailureKind.network),
};

/// The human-readable reason in an error body, in the shapes the common
/// services use: `{"error": {"message"}}` (OpenAI and most others),
/// `{"error": "…"}`, `{"message"}`, `{"detail"}`, and Gemini's one-element
/// list. A body that is not JSON is used as-is when it is short text.
String? errorDetail(String body) {
  final text = body.trim();
  if (text.isEmpty) return null;
  Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return text.startsWith('<') ? null : _clip(text);
  }
  if (json is List && json.isNotEmpty) json = json.first;
  if (json is! Map) return null;
  final error = json['error'];
  final message = switch (error) {
    final Map<String, Object?> e => e['message'],
    final String e => e,
    _ => json['message'] ?? json['detail'],
  };
  return message is String && message.trim().isNotEmpty
      ? _clip(message.trim())
      : null;
}

String _clip(String text) =>
    text.length <= 300 ? text : '${text.substring(0, 300)}…';

String _tryEncode(Object data) {
  try {
    return jsonEncode(data);
  } on Object {
    return '';
  }
}
