/// Pick a weather-tile frame that lines up with a typhoon bulletin time.
library;

/// Largest value in ascending [seconds] that is ≤ [bulletin], or `null` if
/// every frame is newer than the bulletin (or the list is empty).
///
/// Used so radar / Himawari IR under a typhoon overlay match the report time
/// (`track.updated` / cyclone time) instead of "now".
int? closestAtOrBefore(List<int> seconds, int bulletin) {
  if (seconds.isEmpty) return null;
  var lo = 0;
  var hi = seconds.length - 1;
  var ans = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (seconds[mid] <= bulletin) {
      ans = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return ans < 0 ? null : seconds[ans];
}
