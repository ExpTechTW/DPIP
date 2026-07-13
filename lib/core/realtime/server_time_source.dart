import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';

/// Source of corrected server time in ms-since-epoch, behind a seam so the clock
/// is testable without a network.
abstract interface class ServerTimeSource {
  /// The server's current time (offset-corrected ms epoch), or a [Failure].
  Future<Result<int>> serverTimeMs();
}

/// Adapts a raw server-time fetcher to the [Result] contract.
///
/// In production the fetcher is `ExclusiveApi.getNtp` (the offset-corrected
/// `/ntp` round trip). Injecting the function — rather than importing the api
/// surface — keeps `core` from depending on `lib/api`.
class NtpServerTimeSource implements ServerTimeSource {
  const NtpServerTimeSource(this._fetchServerTimeMs);

  final Future<int> Function() _fetchServerTimeMs;

  @override
  Future<Result<int>> serverTimeMs() => guardResult(_fetchServerTimeMs);
}
