/// A published app release shown in the changelog.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'release_note.freezed.dart';
part 'release_note.g.dart';

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

    /// Publish time (ISO-8601 from GitHub).
    @JsonKey(name: 'published_at') required DateTime publishedAt,
  }) = _ReleaseNote;

  factory ReleaseNote.fromJson(Map<String, dynamic> json) =>
      _$ReleaseNoteFromJson(json);
}
