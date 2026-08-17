/// Changelog repository contract.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';

/// Access to the app's published release notes (newest first).
abstract class ChangelogRepository {
  /// How many releases a page holds — GitHub's own maximum is 100; 30 is a
  /// screenful or two. Part of the contract rather than an implementation
  /// detail: "a page shorter than this is the last one" is how a caller knows
  /// to stop asking.
  static const int pageSize = 30;

  /// One page of releases, newest first (ETag-revalidated when possible).
  ///
  /// Paginated rather than exhaustive: a snapshot is published on every push,
  /// so the list only grows, and a page that returns fewer than
  /// [ChangelogApi.pageSize] entries is the last one.
  Future<Result<List<ReleaseNote>>> releases({int page});

  /// The avatar bytes for [login], fetched through the app's Dio stack so the
  /// ETag store caches it like any other asset (the URL is content-addressed:
  /// `avatars.githubusercontent.com/<login>` always means the same picture).
  ///
  /// The bytes are the 64px avatar, rendered by the UI with `Image.memory`.
  Future<Result<Uint8List>> avatarBytes(String login);
}
