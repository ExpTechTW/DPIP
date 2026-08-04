/// Changelog repository contract.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';

/// Access to the app's published release notes (newest first).
abstract class ChangelogRepository {
  /// Fetches releases (ETag-revalidated when possible).
  Future<Result<List<ReleaseNote>>> releases();
}
