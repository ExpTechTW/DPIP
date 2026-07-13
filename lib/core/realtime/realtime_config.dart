/// Timing policy for a realtime channel — cadence and freshness thresholds,
/// separated from the polling mechanism so a feed's tuning is one named preset.
///
/// Thresholds are safety-relevant: too tight flaps live↔stale on normal jitter,
/// too loose shows a dead feed as live. Change a preset deliberately (the
/// staleness classifier is golden-pinned).
class RealtimeConfig {
  const RealtimeConfig({
    required this.pollInterval,
    required this.staleAfter,
    required this.offlineAfter,
  });

  /// How often the channel polls its source.
  final Duration pollInterval;

  /// Data older than this is [staleAfter]-stale (flagged, still shown).
  final Duration staleAfter;

  /// Data older than this — or a connect attempt this long without data — is
  /// treated as offline.
  final Duration offlineAfter;

  /// EEW preset: poll every second, flag stale after 3s of no fresh contact,
  /// offline after 10s. No backoff — an alert must be caught within ~1s even
  /// during a brief outage.
  static const RealtimeConfig eew = RealtimeConfig(
    pollInterval: Duration(seconds: 1),
    staleAfter: Duration(seconds: 3),
    offlineAfter: Duration(seconds: 10),
  );

  /// RTS preset: a continuous ~1 Hz station feed. Poll every second; the source
  /// reports `Err` once snapshots stop arriving (event-recency liveness), so the
  /// channel flags stale after 3s and offline after 10s of no fresh contact.
  /// Provisional (golden-pinned like [eew]) — tune against the live cadence.
  static const RealtimeConfig rts = RealtimeConfig(
    pollInterval: Duration(seconds: 1),
    staleAfter: Duration(seconds: 3),
    offlineAfter: Duration(seconds: 10),
  );
}
