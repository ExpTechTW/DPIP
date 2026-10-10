import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/server_time_source.dart';

/// Tries each [ServerTimeSource] in order and returns the first success.
///
/// Order is precision, not preference: `NtpTimeSource` first because SNTP's
/// RFC 5905 exchange resolves "now" to about a millisecond, then
/// `HttpTimeSource` for the networks that block UDP/123, where one HTTPS round
/// trip gets within hundreds of milliseconds. A later source is consulted only
/// when every earlier one failed, so the accurate path is never traded away for
/// the reachable one.
///
/// A source that returns a [Failure] is a source that declined to answer — both
/// of ours fail closed rather than hand back a reading they could not vouch for
/// — so falling through costs nothing but latency. When all of them decline
/// this returns a [Failure] and `ServerClock` keeps its previous anchor.
class FallbackServerTimeSource implements ServerTimeSource {
  const FallbackServerTimeSource(this._sources);

  final List<ServerTimeSource> _sources;

  @override
  Future<Result<int>> serverTimeMs() async {
    final failures = <String>[];

    for (final source in _sources) {
      final name = source.runtimeType.toString();
      try {
        final result = await source.serverTimeMs();
        final serverMs = result.valueOrNull;
        if (serverMs != null) {
          if (failures.isNotEmpty) {
            Log.info(
              'Time sync fell back to $name after: ${failures.join('; ')}',
            );
          }
          return Ok(serverMs);
        }
        failures.add('$name: ${result.failureOrNull?.message}');
      } catch (error) {
        // A source that throws instead of returning Err must not take the
        // remaining sources down with it.
        failures.add('$name threw: $error');
      }
    }

    return Err(
      NetworkFailure('Every time source failed: ${failures.join('; ')}'),
    );
  }
}
