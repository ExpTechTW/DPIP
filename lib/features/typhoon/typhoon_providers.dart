/// Typhoon feature providers — the v5 meteor typhoon repository.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_api.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_repository_impl.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes the [MeteorTyphoonRepository] so the map's typhoon layer can consume
/// it without importing the feature's `data/`.
List<SingleChildWidget> typhoonProviders(SharedDeps deps) => [
  Provider<MeteorTyphoonRepository>.value(
    value: MeteorTyphoonRepositoryImpl(MeteorTyphoonApi(deps.apiClient)),
  ),
];
