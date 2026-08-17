/// [ChangelogRepository] backed by [ChangelogApi].
library;

import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/changelog/data/changelog_api.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';

/// Owns JSON → [ReleaseNote] mapping and folds transport errors via [guardResult].
class ChangelogRepositoryImpl implements ChangelogRepository {
  const ChangelogRepositoryImpl(this._api);

  final ChangelogApi _api;

  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) =>
      guardResult(() async {
        final raw = await _api.getReleases(page: page);
        return parseReleases(raw);
      });

  @override
  Future<Result<Uint8List>> avatarBytes(String login) =>
      guardResult(() => _api.getAvatarBytes(login));

  /// Skips unmappable entries so one bad release never blanks the list.
  static List<ReleaseNote> parseReleases(List<dynamic> raw) {
    final notes = <ReleaseNote>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        notes.add(ReleaseNote.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Malformed release — skip.
      }
    }
    notes.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return notes;
  }
}
