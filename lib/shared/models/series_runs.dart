/// Where a time series is continuous, and where it merely looks continuous.
///
/// Splitting a series into runs is the whole of "do not draw a line across a
/// hole", and every chart in the app needs the same answer, so the rule lives
/// once instead of in each painter.
///
/// **A hole is usually not a null.** It is tempting to break only where a
/// sample carries no value, and that catches the narrow case — a row that
/// exists but is missing this particular field. It misses the common one: a
/// recorder writes a row when there is something to record, so a radio that
/// was away for six hours leaves *no rows at all*. The list is then two runs
/// of perfectly valid, adjacent entries, and breaking on nulls finds nothing
/// to break on. The line runs straight across the six hours and claims we
/// were watching.
///
/// So a run also ends when the **time** between two entries jumps well past
/// what the series' own spacing has been. The cadence is not assumed: it is
/// configurable per radio and differs per feed, so it is measured from the
/// data (the median interval) and a gap several times that is a hole.
library;

/// One entry: when it was observed, and what was observed — null meaning this
/// row holds nothing for *this* series.
///
/// A null is **not** a boundary. Rows are written when something is worth
/// recording, and what is worth recording arrives on several cadences: a row
/// exists because one field had news, and every other field in it is null for
/// that reason alone. Treating those as holes would chop a one-minute battery
/// series into fragments every time a fifteen-minute counter block landed
/// between two readings. So a null is skipped, and the *time between the
/// readings on either side of it* decides whether anything was missed.
typedef SeriesPoint<T> = (DateTime at, T? value);

/// The shortest hole worth breaking a line for.
///
/// A miss or two at a fast cadence is jitter, not a blackout, and fragmenting
/// the line over it makes an otherwise healthy day look shattered.
const Duration _minimumGap = Duration(minutes: 5);

/// How many typical intervals must pass before silence counts as a hole.
const int _gapFactor = 3;

/// Splits [points] (oldest first) into runs of genuinely continuous
/// observation.
///
/// A run ends at a time gap past [gapThreshold]; nulls are skipped rather than
/// splitting (see [SeriesPoint]). Runs of a single point are kept — a lone
/// reading is real, and it is the caller's business whether to draw it as a
/// dot or drop it.
List<List<SeriesPoint<T>>> splitSeriesRuns<T>(
  List<SeriesPoint<T>> points, {
  Duration? gap,
}) {
  if (points.isEmpty) return const [];
  final threshold = gap ?? gapThreshold(points);
  final runs = <List<SeriesPoint<T>>>[];
  var run = <SeriesPoint<T>>[];
  DateTime? previous;

  void flush() {
    if (run.isNotEmpty) runs.add(run);
    run = <SeriesPoint<T>>[];
  }

  for (final point in points) {
    final (at, value) = point;
    // Skipped, not flushed: `previous` stays on the last real reading, so the
    // gap is measured between observations rather than between rows.
    if (value == null) continue;
    if (previous != null && at.difference(previous) > threshold) flush();
    run.add(point);
    previous = at;
  }
  flush();
  return runs;
}

/// The silence that counts as a hole in this particular series.
///
/// Measured, not assumed: the **median** interval between consecutive
/// readings, times [_gapFactor], floored at [_minimumGap]. The median rather
/// than the mean because one long outage is exactly what we are trying to
/// detect, and a mean would let it raise the bar until it no longer counts.
///
/// Fewer than two readings gives nothing to measure, so the floor stands.
Duration gapThreshold<T>(List<SeriesPoint<T>> points) {
  final gaps = <int>[];
  DateTime? previous;
  for (final (at, value) in points) {
    // Only the intervals between actual readings — rows that say nothing about
    // this series are not part of its cadence.
    if (value == null) continue;
    if (previous != null) gaps.add(at.difference(previous).inMilliseconds);
    previous = at;
  }
  if (gaps.isEmpty) return _minimumGap;
  gaps.sort();
  final median = gaps[gaps.length ~/ 2];
  final scaled = Duration(milliseconds: median * _gapFactor);
  return scaled > _minimumGap ? scaled : _minimumGap;
}
