/// Release-highlights feature providers.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/release_highlights/data/release_highlight_repository.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes [ReleaseHighlightRepository] for the version-highlights page.
List<SingleChildWidget> releaseHighlightsProviders(SharedDeps deps) => [
  Provider<ReleaseHighlightRepository>(
    create: (_) => const ReleaseHighlightRepositoryImpl(),
  ),
];
