/// Applies a [NotifyPreset] through the same [NotifyRepository.setChannel] the
/// per-channel picker uses, one channel at a time.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';

/// Turns a preset into the per-channel writes it needs and sends them in
/// sequence, [spacing] apart.
///
/// There is no batch endpoint: `/v2/notify/{token}/{channel}/{status}` sets
/// one channel, and the backend rate-limits requests for one token over a
/// short window. Back-to-back calls 429 — measured on the 401 recovery in
/// `NotifyRepositoryImpl`, where two requests with no gap between them failed
/// even when each was valid. So the writes go out one at a time with that
/// recovery's own two-second cool-down between consecutive requests, and only
/// for channels that actually differ: moving between neighbouring presets is
/// a handful of requests, and the worst case — all nine — takes about sixteen
/// seconds.
///
/// Each write adopts the server's echo, exactly as a per-channel save does, so
/// `onProgress` always reports what the server holds. The first failure stops
/// the sequence and is returned as-is: what was written stays written, and
/// calling [apply] again resumes, since only the channels still differing are
/// sent.
class NotifyPresetApplier {
  const NotifyPresetApplier(this._repository, {this.spacing = requestSpacing});

  /// The default gap between two consecutive notify requests (see the class
  /// doc for where the number comes from).
  static const Duration requestSpacing = Duration(seconds: 2);

  final NotifyRepository _repository;

  /// The gap kept between consecutive requests of one [apply].
  final Duration spacing;

  /// Sets every channel [preset] covers for [token].
  ///
  /// With [current] the writes are computed against it; without, the settings
  /// are fetched first (onboarding has none yet — and that fetch is also what
  /// registers a push token the backend has never seen). [onProgress] receives
  /// every settings snapshot the server returns along the way. [isCancelled]
  /// is checked before each request, so a caller that has gone away sends
  /// nothing further.
  ///
  /// [NotifyPreset.custom] names no options, so it writes nothing.
  Future<Result<NotifySettings>> apply(
    String token,
    NotifyPreset preset, {
    NotifySettings? current,
    void Function(NotifySettings settings)? onProgress,
    bool Function()? isCancelled,
  }) async {
    var first = true;
    Future<Result<NotifySettings>> send(
      Future<Result<NotifySettings>> Function() request,
    ) async {
      if (!first) await Future<void>.delayed(spacing);
      first = false;
      if (isCancelled?.call() ?? false) {
        return const Err(NetworkFailure('Request cancelled'));
      }
      return request();
    }

    final NotifySettings start;
    if (current != null) {
      start = current;
    } else {
      final fetched = await send(() => _repository.fetch(token));
      switch (fetched) {
        case Ok(:final value):
          start = value;
          onProgress?.call(value);
        case Err():
          return fetched;
      }
    }

    var settings = start;
    for (final change in preset.changesFrom(start)) {
      final saved = await send(
        () => _repository.setChannel(token, change.channel, change.option),
      );
      switch (saved) {
        case Ok(:final value):
          settings = value;
          onProgress?.call(value);
        case Err():
          return saved;
      }
    }
    return Ok(settings);
  }
}
