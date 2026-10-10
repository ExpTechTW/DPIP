import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/fallback_time_source.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubSource implements ServerTimeSource {
  _StubSource(this.name, this.calls, this._result);

  final String name;
  final List<String> calls;
  final Result<int> Function() _result;

  @override
  Future<Result<int>> serverTimeMs() async {
    calls.add(name);
    return _result();
  }
}

void main() {
  test('stops at the first source that answers', () async {
    final calls = <String>[];
    final source = FallbackServerTimeSource([
      _StubSource('sntp', calls, () => const Ok(1000)),
      _StubSource('http', calls, () => const Ok(2000)),
    ]);

    final result = await source.serverTimeMs();

    expect(result.valueOrNull, 1000);
    expect(
      calls,
      ['sntp'],
      reason:
          'HTTP is an order of magnitude less precise — never consulted '
          'while SNTP is answering',
    );
  });

  test('falls through to HTTP when SNTP fails', () async {
    final calls = <String>[];
    final source = FallbackServerTimeSource([
      _StubSource(
        'sntp',
        calls,
        () => const Err(NetworkFailure('UDP/123 blocked')),
      ),
      _StubSource('http', calls, () => const Ok(2000)),
    ]);

    final result = await source.serverTimeMs();

    expect(calls, ['sntp', 'http']);
    expect(result.valueOrNull, 2000);
  });

  test('a throwing source does not take the rest down with it', () async {
    final calls = <String>[];
    final source = FallbackServerTimeSource([
      _StubSource('sntp', calls, () => throw Exception('socket exploded')),
      _StubSource('http', calls, () => const Ok(2000)),
    ]);

    final result = await source.serverTimeMs();

    expect(calls, ['sntp', 'http']);
    expect(result.valueOrNull, 2000);
  });

  test('fails when every source fails', () async {
    final calls = <String>[];
    final source = FallbackServerTimeSource([
      _StubSource('sntp', calls, () => const Err(NetworkFailure('no udp'))),
      _StubSource('http', calls, () => const Err(NetworkFailure('no http'))),
    ]);

    final result = await source.serverTimeMs();

    expect(calls, ['sntp', 'http']);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull?.message, contains('no udp'));
    expect(result.failureOrNull?.message, contains('no http'));
  });

  test('fails on an empty chain rather than reporting a time', () async {
    final result = await const FallbackServerTimeSource([]).serverTimeMs();

    expect(result.isOk, isFalse);
  });
}
