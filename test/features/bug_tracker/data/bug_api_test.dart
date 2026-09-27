/// The bug tracker mirror is a Discord forum shared with other ExpTech
/// products, filtered down to this app by [appBugTag].
///
/// Drop the `tag` query parameter — or drop the `limit` — and the call still
/// succeeds: the tracker answers with a page of *some* product's threads,
/// this app happily renders them as its own bug list, and nobody notices
/// until a user reports a bug that is actually about a different app
/// entirely. This pins the exact index query and the two follow-up reads.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/bug_tracker/data/bug_api.dart';
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

  BugApi apiWith(_FakeAdapter adapter) =>
      BugApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  test('list() caps at 50 and filters to this app\'s tag', () async {
    final adapter = _FakeAdapter((_) => _json('[]', 200));
    await apiWith(adapter).list();

    final sent = adapter.hits.single;
    expect(sent.uri.host, 'bamboo.exptech.dev');
    expect(sent.uri.path, '/api/v1/dc/bug');
    expect(sent.uri.queryParameters, {'limit': '50', 'tag': appBugTag});
  });

  test('list() returns the decoded body', () async {
    final adapter = _FakeAdapter((_) => _json('[{"id":1},{"id":2}]', 200));
    final result = await apiWith(adapter).list();

    expect(result, [
      {'id': 1},
      {'id': 2},
    ]);
  });

  test('thread() reads the single thread by id, no query', () async {
    final adapter = _FakeAdapter((_) => _json('{"id":42}', 200));
    final result = await apiWith(adapter).thread(42);

    expect(
      adapter.hits.single.uri.toString(),
      'https://bamboo.exptech.dev/api/v1/dc/bug/42',
    );
    expect(result, {'id': 42});
  });

  test('avatar() fetches raw bytes from whatever URL it is given', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromBytes(bytes, 200, headers: {}),
    );
    final payload = await apiWith(adapter)
        .avatar('https://cdn.discordapp.com/avatars/1/a.png');

    expect(
      adapter.hits.single.uri.toString(),
      'https://cdn.discordapp.com/avatars/1/a.png',
    );
    expect(payload.bytes, bytes);
  });
}
