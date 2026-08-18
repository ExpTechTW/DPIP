/// A published app release shown in the changelog.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'release_note.freezed.dart';
part 'release_note.g.dart';

/// A GitHub user who contributed to a release — the avatar strip under each
/// changelog card.
@freezed
abstract class ReleaseContributor with _$ReleaseContributor {
  const factory ReleaseContributor({
    /// Login, e.g. `whes1015`.
    required String login,

    /// The user's GitHub profile.
    @Default('') String htmlUrl,
  }) = _ReleaseContributor;

  factory ReleaseContributor.fromJson(Map<String, dynamic> json) =>
      _$ReleaseContributorFromJson(json);
}

/// GitHub serves any login's avatar at a straight URL — no API call involved,
/// and the URL is content-addressed (a login always means the same picture), so
/// the ETag store treats it like an immutable tile.
String avatarUrlFor(String login) =>
    'https://avatars.githubusercontent.com/$login?size=64';

/// One GitHub release, trimmed to what the changelog UI needs.
@freezed
abstract class ReleaseNote with _$ReleaseNote {
  const factory ReleaseNote({
    /// Tag name (`v3.2.1`).
    @JsonKey(name: 'tag_name') required String tagName,

    /// Display title (usually same as [tagName]).
    @Default('') String name,

    /// Markdown body.
    @Default('') String body,

    /// Whether this is a pre-release (公測).
    required bool prerelease,

    /// The release's own page on GitHub — the update destination for a build
    /// that came from no store (a sideloaded APK), where the APK asset lives.
    @JsonKey(name: 'html_url') @Default('') String htmlUrl,

    /// Publish time (ISO-8601 from GitHub).
    @JsonKey(name: 'published_at') required DateTime publishedAt,
  }) = _ReleaseNote;

  factory ReleaseNote.fromJson(Map<String, dynamic> json) =>
      _$ReleaseNoteFromJson(json);
}

/// The distinct `@login` handles mentioned in a release body.
///
/// Every changelog line ends with `— @login` (some also carry a per-line
/// snapshot tag like `· 26w33a`, which the regex deliberately leaves alone),
/// so the contributor strip needs no extra API call — it is parsed from the
/// same body the note already fetched.
List<ReleaseContributor> contributorsFromBody(String body) {
  final logins = <String>{};
  for (final match in _atHandle.allMatches(body)) {
    logins.add(match.group(1)!);
  }
  final out = <ReleaseContributor>[];
  for (final login in logins) {
    out.add(
      ReleaseContributor(login: login, htmlUrl: 'https://github.com/$login'),
    );
  }
  return out;
}

final RegExp _atHandle = RegExp(r'@([a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)');
