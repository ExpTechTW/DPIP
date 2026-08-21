/// Coordinates foreground EEW speech with the notification that plays its
/// configured warning sound.
library;

import 'dart:async';

/// Holds the newest foreground EEW notification while an announcement is
/// speaking, then releases it when the newest announcement completes.
///
/// Background delivery never passes through this gate. A bounded timeout is a
/// safety fallback: a broken or unavailable TTS engine must not suppress the
/// warning notification indefinitely.
class ForegroundEewAnnouncementGate {
  // The monitor controller gives system TTS eight seconds to finish. Keep the
  // independent notification fallback beyond that bound so a slow but healthy
  // voice cannot overlap the alarm; the fallback still prevents a wedged
  // engine from suppressing the warning indefinitely.
  ForegroundEewAnnouncementGate({this.maxHold = const Duration(seconds: 10)});

  final Duration maxHold;

  bool _active = false;
  bool _announcing = false;
  int _generation = 0;
  Future<void> Function()? _pending;
  Timer? _timer;

  /// Whether the visible monitor currently owns foreground EEW sequencing.
  bool get active => _active;

  /// Enables or disables sequencing. Disabling immediately releases anything
  /// pending so leaving the monitor can never swallow a warning.
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    if (!value) {
      _generation++;
      _announcing = false;
      unawaited(_release());
    }
  }

  /// Marks a new report as the announcement that must finish before warning
  /// sound playback. The returned generation identifies that exact report.
  int beginAnnouncement() {
    _announcing = true;
    final generation = ++_generation;
    // A notification retained for the previous serial now belongs to the
    // latest speech sequence. Give that sequence its own full safety window.
    if (_pending != null) {
      _timer?.cancel();
      _timer = Timer(maxHold, () => unawaited(_release()));
    }
    return generation;
  }

  /// Displays immediately unless the monitor is active and an announcement is
  /// in flight. At most the newest notification is retained during rapid EEW
  /// report updates, matching the UI and spoken latest-report policy.
  Future<void> submit(Future<void> Function() display) async {
    if (!_active || !_announcing) {
      await display();
      return;
    }

    _pending = display;
    _timer?.cancel();
    _timer = Timer(maxHold, () => unawaited(_release()));
  }

  /// Releases the pending warning only when [generation] still represents the
  /// newest report. Completion from interrupted speech is ignored.
  Future<void> completeAnnouncement(int generation) async {
    if (generation != _generation) return;
    _announcing = false;
    await _release();
  }

  /// Abandons the current speech wait and releases its pending warning.
  void cancelAnnouncement() {
    _generation++;
    _announcing = false;
    unawaited(_release());
  }

  Future<void> _release() async {
    _timer?.cancel();
    _timer = null;
    _announcing = false;
    final display = _pending;
    _pending = null;
    if (display != null) await display();
  }

  /// Cancels timers. Call only when the owning notification service is torn
  /// down; ordinary monitor deactivation must use [setActive] so it flushes.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
