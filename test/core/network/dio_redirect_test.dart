/// The one place a 3xx has to be followed rather than surfaced.
///
/// notify/location run as a **hot standby**: the standby region answers **307**
/// naming the primary on every live request, not only when the primary is gone
/// — the standby carries no ordinary traffic, so the redirect is the normal
/// path, not the exception. The app asks `core-tnn1`, and on 2026-11-28 tnn1
/// was the standby (`307` → tyo1), so every one of those requests went through
/// it. Following that redirect is
/// therefore not cosmetic — a client that treated it as an error would report a
/// settings write as failed while the write it never made was still missing.
///
/// The behaviour lives in Dio's defaults (`followRedirects: true`,
/// `maxRedirects: 5`), which is exactly the kind of thing that is silently
/// changed later, so it is pinned here against a real server rather than
/// asserted about the options object.
library;

import 'dart:io';

import 'package:dpip/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follows the hot-standby redirect to the primary', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final origin = 'http://${server.address.address}:${server.port}';
    var primaryHits = 0;

    server.listen((request) async {
      if (request.uri.path == '/notify/standby') {
        request.response
          ..statusCode = HttpStatus.temporaryRedirect
          ..headers.set(HttpHeaders.locationHeader, '$origin/notify/primary')
          ..close();
        return;
      }
      primaryHits++;
      request.response
        ..statusCode = HttpStatus.ok
        ..write('[1,0]')
        ..close();
    });

    final response = await createDio().get<dynamic>('$origin/notify/standby');

    expect(response.statusCode, HttpStatus.ok);
    expect(response.data, '[1,0]');
    expect(
      primaryHits,
      1,
      reason: 'the redirect must be followed, not reported',
    );
  });
}
