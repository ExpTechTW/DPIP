/// The reported-bug count for the More-tab badge.
///
/// Loaded lazily the first time the More tab builds and cached for the session
/// — the index payload is small and ETag-cached, so a refresh is cheap, but a
/// counter that re-fetched on every rebuild would hammer the tracker host for
/// a number that changes a few times a week. [refresh] exists for the one flow
/// that should resync immediately: pulling to refresh on the list itself.
library;

import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:flutter/foundation.dart';

class BugTrackerCounter extends ChangeNotifier {
  BugTrackerCounter(this._repository);

  final BugRepository _repository;

  int? _count;
  bool _loaded = false;
  bool _loading = false;

  /// The number of reported bugs, or null while loading / after a failure.
  ///
  /// A failure stays null rather than caching zero: an unreachable tracker
  /// must not read as "no bugs".
  int? get count => _count;

  /// Fetches once per session; later calls are no-ops until [refresh].
  Future<void> ensureLoaded() {
    if (_loaded || _loading) return Future<void>.value();
    return _load();
  }

  /// Re-fetches unconditionally — the pull-to-refresh path.
  Future<void> refresh() => _load();

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final result = await _repository.threads();
    _loaded = true;
    _loading = false;
    _count = result.valueOrNull?.length ?? _count;
    notifyListeners();
  }
}
