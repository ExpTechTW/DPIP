/// Changelog feature providers.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/changelog/data/changelog_api.dart';
import 'package:dpip/features/changelog/data/changelog_repository_impl.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes [ChangelogRepository] for the More → 更新日誌 screen.
List<SingleChildWidget> changelogProviders(SharedDeps deps) => [
  Provider<ChangelogRepository>.value(
    value: ChangelogRepositoryImpl(ChangelogApi(deps.apiClient)),
  ),
];
