/// Provider wiring for CWA tsunami bulletins.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/tsunami/data/tsunami_api.dart';
import 'package:dpip/features/tsunami/data/tsunami_repository_impl.dart';
import 'package:dpip/features/tsunami/domain/tsunami_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes tsunami data to the map layer.
List<SingleChildWidget> tsunamiProviders(SharedDeps deps) => [
  Provider<TsunamiRepository>.value(
    value: TsunamiRepositoryImpl(TsunamiApi(deps.apiClient)),
  ),
];
