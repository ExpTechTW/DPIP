import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/ntp_time_source.dart';
import 'package:dpip/core/realtime/server_time_source.dart';

/// One `/ntp` exchange, measured against the device clock.
///
/// [sentAtMs] and [receivedAtMs] bracket the request so the offset can be
/// corrected for network delay; [dateHeaderMs] is the HTTP `Date` of the same
/// response — see [HttpTimeSource] for what it can and cannot prove.
typedef HttpTimeProbe = ({
  int serverMs,
  int? dateHeaderMs,
  int sentAtMs,
  int receivedAtMs,
});

/// [ServerTimeSource] over `https://api.lb.exptech.dev/ntp`, for networks that
/// block SNTP's UDP/123 — corporate Wi-Fi, hotel and campus networks, some
/// carriers.
///
/// Strictly a fallback behind [NtpTimeSource]: one HTTPS round trip resolves
/// "now" to roughly ±RTT/2 (±150 ms measured), where SNTP's RFC 5905 exchange
/// resolves it to about a millisecond. It exists so a blocked UDP port degrades
/// the clock instead of leaving it uncalibrated.
///
/// ## Why the `Date` header is checked
///
/// The body is the *origin's* clock, and not every origin's clock is right: of
/// the four `lb-*` nodes behind this name, two were 15.7 seconds behind at the
/// time of writing — consistently, and in agreement with each other, so a
/// quorum across them would not have caught it either.
///
/// What does catch it is the `Date` header of the very same response. This host
/// sits behind Cloudflare, so `Date` is stamped at the edge, independently of
/// whichever backend answered — which makes every response self-checking: a
/// body more than [maximumDateSkew] from its own `Date` is a bad backend (or a
/// frozen cache), and is discarded without needing to know which node it came
/// from. Thirty consecutive samples stayed inside 910 ms of their header, so
/// this name does route to healthy backends today; the check is what keeps that
/// from being a thing the app has to assume.
///
/// Every guard fails closed: installing a wrong offset is worse than not
/// calibrating, so a rejected response yields a [Failure] and `ServerClock`
/// keeps its last anchor.
///
/// The [probe] seam lets tests drive every rejection path without a socket;
/// production uses [_httpProbe].
class HttpTimeSource implements ServerTimeSource {
  HttpTimeSource({
    this._hosts = defaultHosts,
    this._timeout = const Duration(seconds: 2),
    this._clock = const SystemClock(),
    Future<HttpTimeProbe> Function(Uri url, Duration timeout)? probe,
  }) : _probe = probe ?? _httpProbe;

  /// The DNS-balanced LB name — the one place the repository uses a bare host.
  ///
  /// `ApiTier` traffic deliberately never does (see `api_region.dart`), because
  /// region selection and failover belong to the app. A clock reading has no
  /// region to select: there is nothing to pin and no per-region failover to
  /// preserve, and the bare name is what Cloudflare terminates with a valid
  /// certificate — `time.exptech.com.tw`, SNTP's own primary, serves `/ntp` too
  /// but presents an expired certificate for the wrong name, and its `Date`
  /// comes from the same machine as its body, so it can neither be reached over
  /// HTTPS nor check itself.
  static const List<String> defaultHosts = ['api.lb.exptech.dev'];

  /// How far the body may sit from its own `Date` header.
  ///
  /// `Date` has one-second resolution and is stamped at the edge after the
  /// origin wrote the body, so a healthy response lands within about a second
  /// of its header (−66 to +910 ms over thirty samples). Two seconds absorbs
  /// that with room to spare, and still rejects the 15.7-second backends by a
  /// factor of seven.
  static const Duration maximumDateSkew = Duration(seconds: 2);

  /// Round trips slower than this are discarded rather than halved.
  ///
  /// The offset estimate assumes the body was stamped at the midpoint of the
  /// exchange, so its error grows with the round trip.
  static const Duration maximumRoundTrip = Duration(milliseconds: 1500);

  /// The body is about twenty bytes; anything larger is not this endpoint.
  static const int _maximumResponseBytes = 1024;

  final List<String> _hosts;
  final Duration _timeout;
  final Clock _clock;
  final Future<HttpTimeProbe> Function(Uri url, Duration timeout) _probe;

  /// The `/ntp` URL for [host]. HTTPS only — a cleartext time source is one any
  /// network in the path can rewrite, and the networks that block UDP/123 are
  /// exactly the ones in a position to do it.
  static Uri urlFor(String host) => Uri.https(host, '/ntp');

  @override
  Future<Result<int>> serverTimeMs() async {
    final rejected = <String>[];

    for (final host in _hosts) {
      final offset = await _offset(host);
      if (offset != null) {
        return Ok(_clock.now().toUtc().add(offset).millisecondsSinceEpoch);
      }
      rejected.add(host);
    }

    return Err(
      NetworkFailure(
        'HTTP time sync rejected every host: ${rejected.join(', ')}',
      ),
    );
  }

  /// The device→server correction [host] reports, or `null` when it is not
  /// trustworthy enough to use.
  Future<Duration?> _offset(String host) async {
    final HttpTimeProbe probe;
    try {
      probe = await _probe(urlFor(host), _timeout).timeout(_timeout);
    } catch (error) {
      Log.warning('HTTP time sync via $host failed: $error');
      return null;
    }

    if (probe.serverMs <= 0) {
      Log.warning('HTTP time sync via $host: unusable body ${probe.serverMs}');
      return null;
    }

    final roundTripMs = probe.receivedAtMs - probe.sentAtMs;
    if (roundTripMs < 0 || roundTripMs > maximumRoundTrip.inMilliseconds) {
      Log.warning(
        'HTTP time sync via $host: round trip ${roundTripMs}ms outside '
        '0..${maximumRoundTrip.inMilliseconds}ms',
      );
      return null;
    }

    final dateHeaderMs = probe.dateHeaderMs;
    if (dateHeaderMs == null) {
      Log.warning('HTTP time sync via $host: no Date header to verify against');
      return null;
    }

    final skewMs = probe.serverMs - dateHeaderMs;
    if (skewMs.abs() > maximumDateSkew.inMilliseconds) {
      Log.warning(
        'HTTP time sync via $host: body disagrees with its own Date header by '
        '${skewMs}ms — treating the backend clock as wrong',
      );
      return null;
    }

    // The body was stamped somewhere inside the exchange; the midpoint is the
    // best estimate a single round trip can give.
    final midpointMs = probe.sentAtMs + roundTripMs ~/ 2;
    return Duration(milliseconds: probe.serverMs - midpointMs);
  }

  /// One `/ntp` round trip over a bare [HttpClient].
  ///
  /// Deliberately not `ApiClient`: every absolute-URL path there runs through
  /// `EtagInterceptor`, and a cached clock reading is worse than no reading.
  /// [HttpClient] also hands back `Date` already parsed, and this request is
  /// not `ApiTier` traffic, so region failover would not apply to it either.
  static Future<HttpTimeProbe> _httpProbe(Uri url, Duration timeout) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = timeout;
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.followRedirects = false;

      final sentAtMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      final response = await request.close();

      // Status before body: a rejected request's body is an HTML error page,
      // and reporting that as "too large" would name the wrong problem.
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }

      final body = await utf8.decoder.bind(response).fold<String>('', (
        buffer,
        chunk,
      ) {
        if (buffer.length + chunk.length > _maximumResponseBytes) {
          throw HttpException('/ntp body too large', uri: url);
        }
        return buffer + chunk;
      });
      final receivedAtMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Unix milliseconds with a fractional part ("1791454316238.287"); the
      // fraction sits far below this path's accuracy.
      return (
        serverMs: double.parse(body.trim()).round(),
        dateHeaderMs: response.headers.date?.toUtc().millisecondsSinceEpoch,
        sentAtMs: sentAtMs,
        receivedAtMs: receivedAtMs,
      );
    } finally {
      client.close(force: true);
    }
  }
}
