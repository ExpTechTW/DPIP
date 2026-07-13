import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/data/radar_repository_impl.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Weather providers: the radar repository (map overlay + home backdrop) — the
/// first of the rain/lightning/typhoon family.
List<SingleChildWidget> weatherProviders(SharedDeps deps) => [
  Provider<RadarRepository>.value(
    value: RadarRepositoryImpl(RadarApi(deps.apiClient)),
  ),
];
