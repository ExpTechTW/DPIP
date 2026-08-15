/// What happened when a permission was asked for.
///
/// A `bool` cannot say the thing that matters. Both the OS platforms prompt for
/// a permission **once**; after that, asking again returns immediately and
/// shows nothing. To a caller that only sees `false`, a fresh refusal and a
/// permanent one look identical — so the button gets tapped, nothing appears,
/// and the app looks broken. It is the single most common way a permission
/// screen dead-ends.
///
/// Distinguishing them is also what decides who acts: on [denied] the app can
/// simply ask again later, while on [needsSettings] the only remaining path
/// runs through system settings — and the user has to be *told* that before
/// being sent there.
///
/// Deciding this belongs in `core/`, but *acting* on it does not: a service
/// must not open a settings page or put up a dialog on the caller's behalf.
/// It reports; the screen explains and navigates.
library;

enum PermissionOutcome {
  /// Granted — nothing more to do.
  granted,

  /// Declined, and the system will ask again next time. The caller may retry
  /// on the next tap without explaining anything.
  denied,

  /// The system will not prompt again. Only its settings can grant this now,
  /// which the user cannot be expected to guess.
  needsSettings,
}
