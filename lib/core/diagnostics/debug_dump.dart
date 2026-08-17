/// The text a diagnostics dump uploads.
library;

/// The most a paste may carry.
///
/// Not a limit of the service — a limit on what anybody will read, and on what
/// a chat window will show without collapsing. The diagnostics are the part
/// that cannot be trimmed (every row answers a question somebody asks), so the
/// log takes whatever is left.
const int dumpLimit = 4000;

const String _diagnosticsHeading = '=== 除錯資訊 ===';
const String _logHeading = '=== 日誌紀錄 ===';

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
