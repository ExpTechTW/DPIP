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

  /// Maps the success value, preserving a failure — and a [Ok.stale] marker,
  /// since a transformed saved copy is still a saved copy.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value, :final stale) => Ok(transform(value), stale: stale),
    Err(:final failure) => Err(failure),
  };
}

/// A successful [Result] carrying [value].
///
/// [stale] is set when [value] is not a fresh answer: the source could not be
/// reached, and what came back is the copy saved from the last time it could
/// (an HTTP stale-if-error, see `StaleIfError`). Such a value is worth showing
/// — an old list beats an error screen — but never as current, so a consumer
/// that renders it says so (`AsyncView` and `FreshnessBanner` do).
final class Ok<T> extends Result<T> {
  const Ok(this.value, {this.stale});

  /// The success value.
  final T value;

  /// Why and since when [value] is a saved copy; null when it is current.
  final Staleness? stale;
}

/// What makes an [Ok] value a saved copy rather than a current answer.
final class Staleness {
  const Staleness({required this.failure, this.since});

  /// Why the current answer is missing.
  final Failure failure;

  /// When the source last confirmed the copy current — server-calibrated
  /// time, comparable with `AppTime.utc`. Null when that was not recorded.
  final DateTime? since;
}

/// A failed [Result] carrying [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The failure.
  final Failure failure;
}

/// A fetched value and, when it is a saved copy rather than the source's
/// current answer, why and since when — what a data source hands its
/// repository so the marker can reach [Ok.stale].
typedef Fetched<T> = ({T data, Staleness? stale});
