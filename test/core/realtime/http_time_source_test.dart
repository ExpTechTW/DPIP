import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/http_time_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

void main() {
  final device = DateTime.utc(2026, 1, 1, 12, 0, 0);
  final deviceMs = device.millisecondsSinceEpoch;

  /// A healthy exchange: 200ms round trip, body agreeing with its own `Date`
  /// to within the header's one-second resolution.
  HttpTimeProbe healthy({int offsetMs = 0, int roundTripMs = 200}) {
    final midpoint = deviceMs + roundTripMs ~/ 2;
    final serverMs = midpoint + offsetMs;
    return (
      serverMs: serverMs,
      // Floored to the second, as a real `Date` header is.
      dateHeaderMs: (serverMs ~/ 1000) * 1000,
      sentAtMs: deviceMs,
      receivedAtMs: deviceMs + roundTripMs,
    );
  }

  HttpTimeSource source({
    required List<String> hosts,
    required Future<HttpTimeProbe> Function(Uri, Duration) probe,
  }) => HttpTimeSource(hosts: hosts, clock: _FixedClock(device), probe: probe);

  test('applies the measured offset to the device clock', () async {
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => healthy(offsetMs: 4000),
    ).serverTimeMs();

    expect(result.valueOrNull, deviceMs + 4000);
  });

  test('corrects for network delay using the exchange midpoint', () async {
    // The body was stamped 500ms after the request left and 500ms before it
    // landed, so the device clock is exactly right and the offset must come
    // out as zero rather than as the full round trip.
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => (
        serverMs: deviceMs + 500,
        dateHeaderMs: deviceMs + 500,
        sentAtMs: deviceMs,
        receivedAtMs: deviceMs + 1000,
      ),
    ).serverTimeMs();

    expect(result.valueOrNull, deviceMs);
  });

  test('rejects a body that disagrees with its own Date header', () async {
    // The real failure behind this name: two of the four lb-* backends were
    // 15.7s behind, consistently and in agreement with each other, so only
    // the Cloudflare-stamped Date header could tell which answer to believe.
    final probe = healthy();
    final result = await source(
      hosts: const ['skewed'],
      probe: (_, _) async => (
        serverMs: probe.serverMs - 15765,
        dateHeaderMs: probe.dateHeaderMs,
        sentAtMs: probe.sentAtMs,
        receivedAtMs: probe.receivedAtMs,
      ),
    ).serverTimeMs();

    expect(
      result.isOk,
      isFalse,
      reason: 'a wrong backend clock must not win, even though it answered',
    );
  });

  test('accepts a Date header floored a second below the body', () async {
    // A healthy response measures +160..+875ms against its own header, purely
    // because `Date` truncates to the second. That must not be rejected.
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => (
        serverMs: deviceMs + 100 + 875,
        dateHeaderMs: deviceMs + 100,
        sentAtMs: deviceMs,
        receivedAtMs: deviceMs + 200,
      ),
    ).serverTimeMs();

    expect(result.isOk, isTrue);
  });

  test('rejects a response with no Date header', () async {
    final probe = healthy();
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => (
        serverMs: probe.serverMs,
        dateHeaderMs: null,
        sentAtMs: probe.sentAtMs,
        receivedAtMs: probe.receivedAtMs,
      ),
    ).serverTimeMs();

    expect(
      result.isOk,
      isFalse,
      reason: 'nothing to check a frozen body against',
    );
  });

  test('rejects a round trip too slow to halve', () async {
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => healthy(roundTripMs: 4600),
    ).serverTimeMs();

    expect(result.isOk, isFalse);
  });

  test('rejects a non-positive body', () async {
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => (
        serverMs: 0,
        dateHeaderMs: deviceMs,
        sentAtMs: deviceMs,
        receivedAtMs: deviceMs + 200,
      ),
    ).serverTimeMs();

    expect(result.isOk, isFalse);
  });

  test('fails when the host cannot be reached', () async {
    // What a blocked UDP port plus an unreachable HTTPS endpoint looks like:
    // no calibration, rather than a guessed one.
    final result = await source(
      hosts: const ['a'],
      probe: (_, _) async => throw Exception('connection refused'),
    ).serverTimeMs();

    expect(result.isOk, isFalse);
    expect(result.failureOrNull?.message, contains('every host'));
  });

  test('falls through a failing host when more than one is given', () async {
    final asked = <String>[];
    final result = await source(
      hosts: const ['down', 'good'],
      probe: (url, _) async {
        asked.add(url.host);
        if (url.host == 'down') throw Exception('connection refused');
        return healthy(offsetMs: -2000);
      },
    ).serverTimeMs();

    expect(asked, ['down', 'good']);
    expect(result.valueOrNull, deviceMs - 2000);
  });

  test('fails rather than hanging when given no hosts', () async {
    final result = await HttpTimeSource(
      hosts: const [],
      clock: _FixedClock(device),
      probe: (_, _) async => healthy(),
    ).serverTimeMs();

    expect(result.isOk, isFalse);
  });

  test('asks the DNS-balanced LB name over HTTPS', () {
    // The one bare host the repository uses: a clock reading has no region to
    // pin, and this is the name Cloudflare terminates with a valid cert.
    expect(HttpTimeSource.defaultHosts, ['api.lb.exptech.dev']);
    expect(
      HttpTimeSource.urlFor(HttpTimeSource.defaultHosts.single).toString(),
      'https://api.lb.exptech.dev/ntp',
    );
  });

  test('never builds a cleartext url', () {
    // A cleartext time source is one any network in the path can rewrite —
    // including the captive portals that block UDP/123 in the first place.
    expect(HttpTimeSource.urlFor('example.test').scheme, 'https');
  });
}
