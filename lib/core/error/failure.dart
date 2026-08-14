/// Base type for recoverable, user-facing failures.
///
/// The data layer maps transport- and platform-specific exceptions into
/// [Failure]s so the presentation layer never depends on those details.
sealed class Failure {
  const Failure(this.message);

  /// Human-readable description safe to surface to the user.
  final String message;
}

/// A network or server-side failure (connectivity, non-2xx response).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// A request that exceeded its time budget — surfaced distinctly so realtime
/// UIs can show a STALE state rather than a generic error.
final class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

/// The response arrived but could not be decoded into the expected shape
/// (unexpected/renamed fields, a non-JSON error body, etc.).
final class DecodeFailure extends Failure {
  const DecodeFailure(super.message);
}

/// The request succeeded but there is no data to show (empty list / 204).
/// Distinct from a failure so the UI can say "nothing right now", not "error".
final class NoDataFailure extends Failure {
  const NoDataFailure(super.message);
}

/// An unexpected, unclassified failure.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// A LoRa radio has no free channel slot left for DPIP's own channel.
///
/// Its own type because the recovery is specific and human: DPIP never
/// overwrites a channel the user configured, so someone has to free a slot.
final class MeshChannelNoSlotFailure extends Failure {
  const MeshChannelNoSlotFailure(super.message);
}

/// A channel with DPIP's name already exists on the radio with a different key.
///
/// Left for the user to resolve on purpose: writing a channel replaces the
/// whole slot, so "fixing" it would swap their key for the published default
/// one — and a licensed radio, which strips PSKs by itself, would turn that fix
/// into an endless rewrite-and-reboot loop.
final class MeshChannelConflictFailure extends Failure {
  const MeshChannelConflictFailure(super.message);
}

/// The OS refused a permission the operation needs (Bluetooth, location…).
///
/// Distinct from other failures so a UI can guide the user to system settings
/// when the permission was permanently denied (which a plain retry can't fix).
final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(super.message);
}
