/// GitHub Releases API for the DPIP changelog.
library;

import 'dart:typed_data';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';

/// Fetches release notes from GitHub. Absolute URL so [EtagInterceptor] can
/// still revalidate (`If-None-Match` / `304`).
class ChangelogApi {
  const ChangelogApi(this._client);

  final ApiClient _client;

  /// `https://api.github.com/repos/ExpTechTW/DPIP/releases`
  static const String releasesUrl =
      'https://api.github.com/repos/ExpTechTW/DPIP/releases';

  /// One page of releases, newest first; drafts are filtered out by GitHub's
  /// default listing.
  ///
  /// Paginated because a snapshot is published on every push, so the list only
  /// grows — and a reader who opens the page wants the top of it, not two
  /// hundred entries fetched to be scrolled past. GitHub takes `page` and
  /// `per_page` and answers a short page when there is no more.
  ///
  /// Cost is bounded by the ETag interceptor rather than by fetching less:
  /// GitHub's unauthenticated limit is 60 requests an hour, and a conditional
  /// request that comes back `304` does not count against it. A page already
  /// seen is therefore free to ask for again.
  ///
  /// Page one is the listing **and** `/releases/latest`, merged.
  ///
  /// One page is not enough on its own any more: a snapshot is published on
  /// every push to main, so within days the newest *stable* release is off
  /// page one — and a stable user would then silently stop being offered
  /// updates, with nothing anywhere reporting a fault. `/releases/latest` is
  /// GitHub's own answer to "the newest non-prerelease", in one request, and
  /// it cannot be pushed off by snapshot volume however many there are.
  ///
  /// Raising `per_page` instead would only move the cliff.
  Future<List<dynamic>> getReleases({int page = 1}) async {
    final body = await _client.getAbsolute(
      releasesUrl,
      query: {'per_page': ChangelogRepository.pageSize, 'page': page},
      headers: _headers,
    );
    final releases = [...(body as List?) ?? const []];

    // Only on the first page. `/releases/latest` is a *supplement* for the
    // newest stable, which a page of snapshots would otherwise bury; adding it
    // to page two would merely repeat it.
    if (page > 1) return releases;

    try {
      final latest = await _client.getAbsolute(
        '$releasesUrl/latest',
        headers: _headers,
      );
      if (latest is Map) {
        final tag = latest['tag_name'];
        // Only when the page did not already carry it — the merge must not
        // create a duplicate for `findUpdate` to rank against itself.
        final known = releases.any((r) => r is Map && r['tag_name'] == tag);
        if (!known) releases.add(latest);
      }
    } on Object {
      // A repository with no published stable release answers 404 here, and a
      // page of snapshots is still a useful answer. Never let the supplement
      // fail the primary.
    }
    return releases;
  }

  /// The avatar bytes for [login]. `avatars.githubusercontent.com` answers any
  /// login with its 64px picture; bytes round-trip through the ETag store so
  /// revisits are local.
  Future<Uint8List> getAvatarBytes(String login) async {
    final payload = await _client.getBytesAbsolute(avatarUrlFor(login));
    return payload.bytes;
  }

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
}
