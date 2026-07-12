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
