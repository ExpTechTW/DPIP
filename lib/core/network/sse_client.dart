import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_event.dart';

/// How often DPIP's SSE servers write a `: ping` comment on a stream that has
/// nothing else to send — the LB hubs (EEW) and the TREM stream (RTS) both.
///
/// A fact about the servers, not a client setting: the silence limit below is
/// derived from it, so if the servers ping more often this is the one number to
/// change, and detection of a dead connection speeds up with it.
const Duration sseServerPingInterval = Duration(seconds: 60);

/// How long an SSE connection may deliver nothing at all — no frame, no ping —
/// before it is treated as dead: 2.2 × [sseServerPingInterval].
///
/// A connection can die without closing. A network handover or a NAT mapping
/// that times out leaves a half-open socket: no FIN, no RST, no error, just
/// silence, and a client that reads silence as "nothing to report" shows a
/// live, calm feed that can no longer receive an alert. The servers' pings are
/// what make silence meaningful, so the bound is counted in pings.
///
/// Two intervals, not one, plus 10 %: the LB hub only checks whether a ping is
/// due when its wait ends, and a wake that finds nothing new restarts that
/// wait — so the gap between two bytes on a healthy stream can approach two
/// full intervals. The 10 % covers scheduling and transit. Any tighter and a
/// healthy quiet stream would be torn down; any looser and a dead one passes
/// for quiet that much longer.
const Duration sseSilenceLimit = Duration(seconds: 132);

/// Opens a Server-Sent Events connection and parses its `text/event-stream`
/// body into [SseEvent] frames — the transport seam a streaming feed sits on.
///
/// One [connect] call is **one** connection: the returned stream ends (or
/// errors) when the server closes it. Reconnection policy (retry hint, backoff)
/// is the caller's concern, so this stays a pure parser and the source owns the
/// app-level liveness rules. Region failover is inherited from [ApiClient].
abstract interface class SseClient {
  /// Opens an SSE connection to [path] on [tier] and yields its frames.
  Stream<SseEvent> connect(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
  });
}

/// [SseClient] backed by the region-aware [ApiClient].
class HttpSseClient implements SseClient {
  const HttpSseClient(this._api);

  final ApiClient _api;

  @override
  Stream<SseEvent> connect(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
  }) async* {
    final response = await _api.openStream(
      tier,
      path,
      query: query,
      // The transport's own backstop for a half-open socket: it errors the
      // stream after this long without a byte, so a dead connection is
      // replaced even while nothing is polling the source (the app sits
      // behind a notification shade, where the socket is deliberately kept).
      idleTimeout: sseSilenceLimit,
      headers: const {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        // Override the client-wide gzip: a ResponseType.stream is not
        // auto-decompressed, so a compressed event-stream would parse as
        // garbage. SSE is uncompressed by convention; make that explicit.
        'Accept-Encoding': 'identity',
      },
    );
    try {
      yield* parse(response.stream);
    } finally {
      response.cancel();
    }
  }

  /// Parses a byte stream of `text/event-stream` into frames.
  ///
  /// Chunk-boundary safe: `utf8.decoder` and `LineSplitter` both buffer partial
  /// input across network chunks, so a multi-byte character or a line split
  /// mid-chunk is reassembled correctly. A frame is emitted on each blank-line
  /// delimiter; each `:`-prefixed comment line (a server keep-alive) is emitted
  /// at once as an [SseEvent.comment], without touching the frame being
  /// assembled around it; multiple `data:` lines are joined with `\n` per the
  /// spec (trailing newline stripped). Exposed for unit testing the parser
  /// directly.
  ///
  /// Uses `utf8.decoder.bind` rather than `bytes.transform(utf8.decoder)`: Dio's
  /// response stream is a `Stream<Uint8List>` at runtime, and `Stream.transform`
  /// reifies its input type from the receiver — so it would demand a
  /// `StreamTransformer<Uint8List, String>` and reject the decoder (a
  /// `StreamTransformer<List<int>, String>`). `bind` takes the stream as a
  /// parameter, so `Stream<Uint8List>` is accepted covariantly.
  static Stream<SseEvent> parse(Stream<List<int>> bytes) async* {
    String? name;
    final data = StringBuffer();
    var dataLines = 0;
    Duration? retry;
    var dirty = false;

    final lines = const LineSplitter().bind(utf8.decoder.bind(bytes));
    await for (final line in lines) {
      if (line.isEmpty) {
        if (dirty) {
          yield SseEvent(name: name, data: data.toString(), retry: retry);
        }
        name = null;
        data.clear();
        dataLines = 0;
        retry = null;
        dirty = false;
        continue;
      }
      if (line.startsWith(':')) {
        // A keep-alive: no content, but proof the connection still delivers.
        var text = line.substring(1);
        if (text.startsWith(' ')) text = text.substring(1);
        yield SseEvent.comment(text);
        continue;
      }
      dirty = true;
      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'event':
          name = value;
        case 'data':
          // The separator goes *between* lines, never after the last one, so
          // the buffer already holds the spec's joined form and [toString]
          // is the frame: the trailing-newline strip that used to follow it
          // copied every payload once more — at 1 Hz on RTS, a 20 KB string
          // per second for nothing. Same output: `a`,`b` → `a\nb`; an empty
          // `data:` line still contributes its empty string.
          if (dataLines > 0) data.write('\n');
          data.write(value);
          dataLines++;
        case 'retry':
          final ms = int.tryParse(value);
          if (ms != null) retry = Duration(milliseconds: ms);
        // 'id' and unknown fields are ignored: DPIP's feeds are snapshot
        // streams, so Last-Event-ID resumption is not used.
      }
    }
  }
}
