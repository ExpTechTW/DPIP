import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_event.dart';

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
  /// delimiter; `:`-prefixed comment lines (SSE heartbeats) are skipped;
  /// multiple `data:` lines are joined with `\n` per the spec (trailing newline
  /// stripped). Exposed for unit testing the parser directly.
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
    Duration? retry;
    var dirty = false;

    final lines = const LineSplitter().bind(utf8.decoder.bind(bytes));
    await for (final line in lines) {
      if (line.isEmpty) {
        if (dirty) {
          yield SseEvent(
            name: name,
            data: _stripTrailingNewline(data.toString()),
            retry: retry,
          );
        }
        name = null;
        data.clear();
        retry = null;
        dirty = false;
        continue;
      }
      if (line.startsWith(':')) continue; // comment / heartbeat
      dirty = true;
      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'event':
          name = value;
        case 'data':
          data
            ..write(value)
            ..write('\n');
        case 'retry':
          final ms = int.tryParse(value);
          if (ms != null) retry = Duration(milliseconds: ms);
        // 'id' and unknown fields are ignored: DPIP's feeds are snapshot
        // streams, so Last-Event-ID resumption is not used.
      }
    }
  }

  static String _stripTrailingNewline(String s) =>
      s.endsWith('\n') ? s.substring(0, s.length - 1) : s;
}
