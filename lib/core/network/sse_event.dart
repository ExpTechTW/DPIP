/// One parsed Server-Sent Events frame.
///
/// A frame is the group of lines between blank-line delimiters in a
/// `text/event-stream` body. Only the fields the app uses are surfaced:
/// - [name] is the `event:` type (`null`/`message` for the default event that
///   carries the feed payload; named events like `info` are metadata).
/// - [data] is the concatenated `data:` lines (spec-joined by `\n`, trailing
///   newline stripped) — for DPIP's feeds this is the same JSON the one-shot GET
///   returns, so the data format is unchanged by moving to SSE.
/// - [retry] is the server's reconnect hint (`retry:` in ms), used to pace
///   reconnection.
///
/// `id:` is not modelled: DPIP's feeds are snapshot streams (each event is the
/// current state), so Last-Event-ID resumption is not used.
class SseEvent {
  const SseEvent({this.name, this.data = '', this.retry});

  /// The `event:` type, or null for the default (unnamed) event.
  final String? name;

  /// The concatenated `data:` payload; empty for a metadata-only frame.
  final String data;

  /// The server's `retry:` reconnect hint, or null if the frame carried none.
  final Duration? retry;

  /// Whether this is the default event that carries the feed payload (the one
  /// the source decodes); named events (e.g. `info`) are ignored for payload.
  bool get isDefault => name == null || name!.isEmpty || name == 'message';

  @override
  String toString() => 'SseEvent(name: $name, data: $data, retry: $retry)';
}
