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
/// A `:` comment line is surfaced too, as its own [SseEvent.comment]. The spec
/// says to ignore comments, and as *content* they are ignored — [isDefault] is
/// false, so nothing decodes one — but the servers write `: ping` on a stream
/// with nothing else to say, and that ping is the only way a client can tell a
/// quiet connection from one that silently died. Dropping it in the parser
/// would leave the source blind to exactly the failure it most needs to see.
///
/// `id:` is not modelled: DPIP's feeds are snapshot streams (each event is the
/// current state), so Last-Event-ID resumption is not used.
class SseEvent {
  const SseEvent({this.name, this.data = '', this.retry}) : isComment = false;

  /// A `:` comment line — a server keep-alive. [data] holds the text after the
  /// colon (`ping`, `ping 1700000000000`), for logging only.
  const SseEvent.comment([this.data = ''])
    : name = null,
      retry = null,
      isComment = true;

  /// The `event:` type, or null for the default (unnamed) event.
  final String? name;

  /// The concatenated `data:` payload; empty for a metadata-only frame.
  final String data;

  /// The server's `retry:` reconnect hint, or null if the frame carried none.
  final Duration? retry;

  /// Whether this is a comment line rather than a frame: proof the connection
  /// is alive, and nothing else.
  final bool isComment;

  /// Whether this is the default event that carries the feed payload (the one
  /// the source decodes); named events (e.g. `info`) and comments are ignored
  /// for payload.
  bool get isDefault =>
      !isComment && (name == null || name!.isEmpty || name == 'message');

  @override
  String toString() => isComment
      ? 'SseEvent.comment($data)'
      : 'SseEvent(name: $name, data: $data, retry: $retry)';
}
