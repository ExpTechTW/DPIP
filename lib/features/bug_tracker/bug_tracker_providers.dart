/// Bug-tracker feature providers.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/features/bug_tracker/data/bug_api.dart';
import 'package:dpip/features/bug_tracker/data/bug_repository_impl.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes the bug-tracker repository for the More → 已回報的錯誤 screen.
///
/// The page depends on the domain interfaces only; the API-backed
/// implementation lives here, at the feature root, so the page never imports
/// a data layer.
List<SingleChildWidget> bugTrackerProviders(SharedDeps deps) {
  final repository = BugRepositoryImpl(BugApi(deps.apiClient));
  return [
    Provider<BugRepository>.value(value: repository),
    ChangeNotifierProvider<BugTrackerCounter>(
      create: (_) => BugTrackerCounter(repository),
    ),
  ];
}
