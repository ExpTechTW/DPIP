/// Base type for recoverable, user-facing failures.
///
/// The data layer maps transport- and platform-specific exceptions into
/// [Failure]s so the presentation layer never depends on those details.
sealed class Failure {
  const Failure(this.message);

  /// Human-readable description safe to surface to the user.
  final String message;
}

/// A network or server-side failure.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// An unexpected, unclassified failure.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
