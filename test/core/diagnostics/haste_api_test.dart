/// The paste-service reply shape is inconsistent on purpose (`key` for a
/// fresh paste, only `url` on some paths) and always plain HTTP.
///
/// Getting the precedence backwards — reading `url` before `key` — would
/// still produce a link, so nothing crashes and nothing looks wrong in a
/// screenshot; the diagnosis just becomes "click here" over an unencrypted
/// connection handed to whoever reads the bug report. Every branch of that
/// precedence, plus the scheme rewrite, is pinned here.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/diagnostics/haste_api.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> hits = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hits.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionSelection regions;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
  });

  HasteApi apiWith(_FakeAdapter adapter) =>
      HasteApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  test('posts the content as a log-language paste', () async {
    final adapter = _FakeAdapter((_) => _json('{"key":"abc123"}', 200));
    await apiWith(adapter).upload('a log line');

    final sent = adapter.hits.single;
    expect(sent.method, 'POST');
    expect(sent.uri.toString(), 'https://haste.exptech.dev/api/pastes');
    expect(sent.data, {'content': 'a log line', 'language': 'log'});
  });

  test('a key builds the link even when url is also present', () async {
    final adapter = _FakeAdapter(
      (_) =>
          _json('{"key":"abc123","url":"http://haste.exptech.dev/wrong"}', 200),
    );
    final link = await apiWith(adapter).upload('x');

    expect(link, 'https://haste.exptech.dev/abc123');
  });

  test('an empty key falls back to url, rewritten to https', () async {
    final adapter = _FakeAdapter(
      (_) => _json('{"key":"","url":"http://haste.exptech.dev/abc123"}', 200),
    );
    final link = await apiWith(adapter).upload('x');

    expect(link, 'https://haste.exptech.dev/abc123');
  });

  test('url is used as-is when already https', () async {
    final adapter = _FakeAdapter(
      (_) => _json('{"url":"https://haste.exptech.dev/abc123"}', 200),
    );
    final link = await apiWith(adapter).upload('x');

    expect(link, 'https://haste.exptech.dev/abc123');
  });

  test('neither key nor url present is null, not a crash', () async {
    final adapter = _FakeAdapter((_) => _json('{}', 200));
    expect(await apiWith(adapter).upload('x'), isNull);
  });

  test('an empty url string is null rather than an empty link', () async {
    final adapter = _FakeAdapter((_) => _json('{"url":""}', 200));
    expect(await apiWith(adapter).upload('x'), isNull);
  });

  test('a non-Map body is null rather than a thrown type error', () async {
    final adapter = _FakeAdapter((_) => _json('[1,2,3]', 200));
    expect(await apiWith(adapter).upload('x'), isNull);
  });
}
