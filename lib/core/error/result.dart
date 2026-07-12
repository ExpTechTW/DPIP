import 'package:dpip/core/error/failure.dart';

/// The outcome of an operation that can fail with a [Failure].
///
/// Data-layer methods return a `Result<T>` instead of throwing, so callers must
/// handle failure explicitly — a swallowed exception can never surface as a
/// silent "all clear", which for a safety-critical app is the worst failure
/// mode. Pattern-match with [when], or read [valueOrNull] / [failureOrNull].
sealed class Result<T> {
  const Result();

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// The value when [Ok], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure when [Err], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Err(:final failure) => failure,
    Ok() => null,
  };

  /// Folds both cases into a single value.
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final failure) => err(failure),
  };

  /// Maps the success value, preserving a failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

/// A successful [Result] carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The success value.
  final T value;
}

/// A failed [Result] carrying [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The failure.
  final Failure failure;
}
