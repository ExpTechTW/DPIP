/// Provider wiring for the disaster-prevention map feature.
library;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_api.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_repository_impl.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Disaster-prevention map (AED / future DPM layers) providers.
List<SingleChildWidget> disasterMapProviders(SharedDeps deps) => [
  Provider<DisasterMapRepository>.value(
    value: DisasterMapRepositoryImpl(DisasterMapApi(deps.apiClient)),
  ),
];
