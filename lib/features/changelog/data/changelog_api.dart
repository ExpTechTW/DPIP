/// GitHub Releases API for the DPIP changelog.
library;

import 'package:dpip/core/network/api_client.dart';

/// Fetches release notes from GitHub. Absolute URL so [EtagInterceptor] can
/// still revalidate (`If-None-Match` / `304`).
class ChangelogApi {
  const ChangelogApi(this._client);

  final ApiClient _client;

  /// `https://api.github.com/repos/ExpTechTW/DPIP/releases`
  static const String releasesUrl =
      'https://api.github.com/repos/ExpTechTW/DPIP/releases';

  /// Newest first; drafts are filtered out by GitHub's default listing.
  ///
  /// The listing **and** `/releases/latest`, merged.
  ///
  /// One page is not enough on its own any more: a snapshot is published on
  /// every push to main, so within days the newest *stable* release is off
  /// page one — and a stable user would then silently stop being offered
  /// updates, with nothing anywhere reporting a fault. `/releases/latest` is
  /// GitHub's own answer to "the newest non-prerelease", in one request, and
  /// it cannot be pushed off by snapshot volume however many there are.
  ///
  /// Raising `per_page` instead would only move the cliff.
  Future<List<dynamic>> getReleases() async {
    final page = await _client.getAbsolute(
      releasesUrl,
      query: const {'per_page': 30},
      headers: _headers,
    );
    final releases = [...(page as List?) ?? const []];

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

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
}
