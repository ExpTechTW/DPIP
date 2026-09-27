/// GitHub's releases index and its `/latest` alias disagree on what "latest"
/// means whenever the newest tag is a pre-release: `/latest` skips it, so the
/// changelog re-fetches `/latest` and merges it back in — but only on page 1,
/// and only once, since asking again on every page would just re-append the
/// same release forever.
///
/// The merge is a dedupe by `tag_name`, and the `/latest` call is expected to
/// 404 outright on a repo with no stable release at all — a fault this method
/// swallows deliberately rather than failing the whole page over a release
/// that doesn't exist. Get the swallow too broad and a real outage looks like
/// "no stable release"; get the dedupe wrong and the newest release doubles
/// up at the top of the list.
///
/// Separately, the page's own body is unwrapped with `(body as List?) ??
/// const []`, which reads as "anything unexpected becomes no releases" but
/// only actually catches `null` — a non-list, non-null body still throws.
/// That is pinned below as the real behaviour rather than papered over.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/changelog/data/changelog_api.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
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

  ChangelogApi apiWith(_FakeAdapter adapter) =>
      ChangelogApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  test(
    'page 1 asks GitHub for pageSize releases with the API headers',
    () async {
      final adapter = _FakeAdapter((options) {
        if (options.uri.path.endsWith('/latest')) return _json('{}', 404);
        return _json('[]', 200);
      });
      await apiWith(adapter).getReleases();

      final list = adapter.hits.first;
      expect(list.uri.host, 'api.github.com');
      expect(list.uri.path, '/repos/ExpTechTW/DPIP/releases');
      expect(list.uri.queryParameters, {
        'per_page': '${ChangelogRepository.pageSize}',
        'page': '1',
      });
      expect(list.headers['Accept'], 'application/vnd.github+json');
      expect(list.headers['X-GitHub-Api-Version'], '2022-11-28');
    },
  );

  test('a pre-release-only latest is merged into page 1', () async {
    final adapter = _FakeAdapter((options) {
      if (options.uri.path.endsWith('/latest')) {
        return _json('{"tag_name":"v1.0.0"}', 200);
      }
      return _json('[{"tag_name":"v1.1.0-rc"}]', 200);
    });
    final releases = await apiWith(adapter).getReleases();

    expect(releases, [
      {'tag_name': 'v1.1.0-rc'},
      {'tag_name': 'v1.0.0'},
    ]);
  });

  test('latest is not appended again when already on the page', () async {
    final adapter = _FakeAdapter((options) {
      if (options.uri.path.endsWith('/latest')) {
        return _json('{"tag_name":"v1.0.0"}', 200);
      }
      return _json('[{"tag_name":"v1.0.0"},{"tag_name":"v0.9.0"}]', 200);
    });
    final releases = await apiWith(adapter).getReleases();

    expect(releases, hasLength(2));
  });

  test('a repo with no stable release swallows the /latest 404', () async {
    final adapter = _FakeAdapter((options) {
      if (options.uri.path.endsWith('/latest')) return _json('{}', 404);
      return _json('[{"tag_name":"v0.1.0-beta"}]', 200);
    });
    final releases = await apiWith(adapter).getReleases();

    // The /latest call was attempted and its failure swallowed — the page's
    // own releases still come back rather than the whole call failing.
    expect(adapter.hits, hasLength(2));
    expect(releases, [
      {'tag_name': 'v0.1.0-beta'},
    ]);
  });

  test('page > 1 never asks for /latest at all', () async {
    final adapter = _FakeAdapter((_) => _json('[{"tag_name":"v0.5.0"}]', 200));
    final releases = await apiWith(adapter).getReleases(page: 2);

    expect(adapter.hits, hasLength(1));
    expect(adapter.hits.single.uri.queryParameters['page'], '2');
    expect(releases, [
      {'tag_name': 'v0.5.0'},
    ]);
  });

  test(
    'a non-list, non-null page body throws rather than falling back',
    () async {
      // `[...(body as List?) ?? const []]` looks like it treats any
      // unexpected shape as "no releases", but `as List?` only tolerates an
      // actual `null` — a Map still fails the cast and throws. This pins the
      // real behaviour, not the apparent intent of the `?? const []`.
      final adapter = _FakeAdapter((options) {
        if (options.uri.path.endsWith('/latest')) return _json('{}', 404);
        return _json('{"message":"not an array"}', 200);
      });

      await expectLater(
        () => apiWith(adapter).getReleases(),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test('getAvatarBytes fetches the sized GitHub avatar URL as bytes', () async {
    final bytes = Uint8List.fromList([9, 8, 7]);
    final adapter = _FakeAdapter(
      (_) => ResponseBody.fromBytes(bytes, 200, headers: {}),
    );
    final result = await apiWith(adapter).getAvatarBytes('octocat');

    expect(adapter.hits.single.uri.toString(), avatarUrlFor('octocat'));
    expect(result, bytes);
  });
}
