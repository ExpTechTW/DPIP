import 'package:dpip/core/realtime/server_clock.dart';

/// Global, calibrated time — the app-wide facade over the NTP-synced
/// [ServerClock].
///
/// Like `Log`, a thin static wrapper so any layer can read corrected time
/// without threading the clock through constructors ("類似 flutter_time 封裝").
/// [install] wires the shared clock at bootstrap; before that (and before the
/// first sync) it degrades to device time, so a caller never gets null.
///
/// - [utc] is the corrected UTC instant.
/// - [utc8] is the same instant with Taiwan's fixed **+8** offset applied: its
///   year/month/day/hour/… fields read as Taipei wall time regardless of the
///   device's timezone (the [DateTime] is flagged UTC by construction).
///
/// The underlying [ServerClock] is monotonic-anchored, so calibrated time is
/// immune to device-clock and timezone changes between syncs; a background
/// 60-second resync keeps the anchor fresh.
abstract final class AppTime {
  AppTime._();

  static ServerClock? _clock;

  /// Wires the shared calibrated clock. Called once at bootstrap.
  static void install(ServerClock clock) => _clock = clock;

  /// Calibrated current time in UTC (device time until the first sync).
  static DateTime get utc => _clock?.now() ?? DateTime.now().toUtc();

  /// Calibrated current time at Taiwan's fixed +8 offset.
  static DateTime get utc8 => taipei(utc);

  /// [utc] at Taiwan's fixed +8 offset — its year/month/day/hour/… fields read
  /// as Taipei wall time regardless of the device timezone (UTC-flagged). For
  /// a server timestamp, feed it the UTC instant this calendar moment holds.
  static DateTime taipei(DateTime utc) =>
      utc.toUtc().add(const Duration(hours: 8));

  /// Whether the clock has completed at least one NTP sync.
  static bool get isSynced => _clock?.isSynced ?? false;

  /// Re-expresses a timestamp minted by the **device** clock in calibrated
  /// time, so it can be compared with [utc].
  ///
  /// Needed wherever a stamp comes from outside the app and carries the
  /// device's own idea of now — an OS location fix, a filesystem mtime. Ageing
  /// such a stamp against [utc] measures the clock offset plus the age, and on
  /// a device whose clock runs ahead it yields a *negative* age, which reads
  /// as "newer than now" and passes every freshness test.
  ///
  /// Before the first sync the correction is zero and this is the identity, as
  /// it should be: with no calibration the device clock is all there is.
  static DateTime fromDevice(DateTime deviceStamp) =>
      deviceStamp.toUtc().add(_clock?.offset ?? Duration.zero);

  /// Forces an immediate resync (best-effort; no-op before [install]).
  static Future<void> sync() async => _clock?.sync();
}
