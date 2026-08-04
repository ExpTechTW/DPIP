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
  Future<List<dynamic>> getReleases() async {
    final raw = await _client.getAbsolute(
      releasesUrl,
      query: const {'per_page': 30},
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    return (raw as List?) ?? const [];
  }
}
