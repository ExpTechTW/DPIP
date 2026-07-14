/// The combined location-availability state, driving both the reporting
/// lifecycle and the user-facing "fix it" banner.
///
/// It folds the OS location-services toggle and the permission grant into one
/// value so the app can react to a mid-session change (GPS turned off, or a
/// permission revoked) with a clear message and a Settings deep-link, instead of
/// an uncaught exception.
enum LocationStatus {
  /// Services on and background ("Always") granted — fully usable.
  ready,

  /// Services on and foreground granted, but not background ("Always"); the
  /// app works in the foreground, background reporting can't arm.
  whileInUseOnly,

  /// Location services (GPS) are turned off system-wide.
  serviceOff,

  /// Permission denied but still re-requestable via a prompt.
  denied,

  /// Permission permanently denied — only the system Settings can restore it.
  deniedForever,
}
