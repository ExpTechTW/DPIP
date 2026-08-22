/// The text a diagnostics dump uploads.
library;

/// The most a paste may carry.
///
/// Not a limit of the service — a limit on what anybody will read, and on what
/// a chat window will show without collapsing. The diagnostics are the part
/// that cannot be trimmed (every row answers a question somebody asks), so the
/// log takes whatever is left.
const int dumpLimit = 39995;

const String _diagnosticsHeading = '=== 除錯資訊 ===';
const String _logHeading = '=== 日誌紀錄 ===';

final RegExp _coordinateValue = RegExp(
  r'((?:"|\b)(?:centreLat|centerLat|centreLng|centerLng|latitude|longitude|lat|lon|lng)"?\s*[:=]\s*)(-?\d+(?:\.\d+)?)',
  caseSensitive: false,
);

final RegExp _coordinatePair = RegExp(
  r'(^|[^\d.])(-?\d{1,2}\.\d{3,})\s*,\s*(-?\d{1,3}\.\d{3,})([^\d.]|$)',
  multiLine: true,
);

/// Removes precise locations from the final text immediately before upload.
///
/// Structured diagnostics are nulled by label before this point. This final
/// boundary also covers coordinates embedded in free-form log lines, including
/// the native background-location path which is not represented by
/// [DiagnosticsField]. Device identifiers and push tokens deliberately remain:
/// they are support lookup keys, while the coordinates are the personal value
/// the user must explicitly consent to send. The literal `null` is intentional:
/// silently deleting a value makes a reader mistake privacy filtering for
/// missing diagnostics.
String redactSensitiveDump(String content) {
  final redacted = content.replaceAllMapped(
    _coordinateValue,
    (match) => '${match[1]}null',
  );
  return redacted.replaceAllMapped(
    _coordinatePair,
    (match) => '${match[1]}null,null${match[4]}',
  );
}

/// Builds the dump: diagnostics whole, then as much log as still fits.
///
/// [logLines] is newest first — the order the store and Talker's history both
/// return — and lines are taken from the front, because the end of a log is
/// the part that explains what just happened. They are written oldest first,
/// so the result reads forwards.
///
/// The diagnostics are never cut. If they alone exceed [limit] the log is
/// dropped entirely rather than a row of the diagnostics being lost: a partial
/// diagnostic reads as a complete one and is answered as if it were.
String buildDump({
  required String diagnostics,
  required List<String> logLines,
  int limit = dumpLimit,
}) {
  final head = '$_diagnosticsHeading\n${diagnostics.trim()}\n\n$_logHeading\n';
  final taken = <String>[];
  var used = head.length;

  for (final line in logLines) {
    // `+ 1` for the newline this line brings with it.
    if (used + line.length + 1 > limit) break;
    used += line.length + 1;
    taken.add(line);
  }

  return '$head${taken.reversed.join('\n')}'.trimRight();
}
