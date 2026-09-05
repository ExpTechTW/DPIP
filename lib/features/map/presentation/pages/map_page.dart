/// Full-screen map tab — assembles overlay layers for [MapScaffold].
library;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/features/map/presentation/layers/humidity_layer.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/features/map/presentation/layers/lightning_layer.dart';
import 'package:dpip/features/map/presentation/layers/mesh_node_layer.dart';
import 'package:dpip/features/map/presentation/layers/pressure_layer.dart';
import 'package:dpip/features/map/presentation/layers/qpesums_layer.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/layers/rain_layer.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/map/presentation/layers/temperature_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_layer.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen map tab.
///
/// Just business logic now: it names the layers this surface offers and hands
/// them to [MapScaffold], which owns the map, the layer switcher, and the
/// timeline. Adding radar/rain/lightning/… later is one more entry in [_layers].
///
/// The initial overlay comes from [DefaultMapLayerController]; a [ValueKey] on
/// the scaffold remounts when that preference changes so the new default wins.
/// The key is keyed on the *preference*, not on visibility — hiding the
/// currently-open layer must not remount the whole scaffold (that would close
/// any sheet open above it, such as the layer-order editor the hide was just
/// tapped from). A hidden layer drops out of the picker's list entirely — the
/// order editor's eye toggle is the only way to offer it again. A hide that
/// removes the on-screen layer mid-session is handled by [MapScaffold] itself,
/// which watches [MapLayerVisibilityController] directly and falls back in
/// place.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  /// Shell branch index of the map tab — [BaseMap] pauses its native render
  /// loop while this tab is hidden.
  static const int tabIndex = 2;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Built once so each layer keeps its own MapLibre state across rebuilds.
  late final List<MapLayer> _layers = [
    RadarMapLayer(
      context.read<RadarRepository>(),
      context.read<MapReferenceOutlineController>(),
    ),
    // The wind-forecast block sits right after radar: the picker groups by
    // category in declared order, and the numerical-forecast group (QPESUMS
    // then ECMWF then GFS) is what radar hands off to.
    QpesumsMapLayer(
      context.read<QpesumsRepository>(),
      context.read<MapReferenceOutlineController>(),
    ),
    for (final model in WindForecastModel.values)
      WindForecastMapLayer(
        context.read<Map<WindForecastModel, WindForecastRepository>>()[model]!,
        model: model,
        referenceOutline: context.read<MapReferenceOutlineController>(),
      ),
    // One layer per satellite channel — each fetches its own frame list and
    // serves its own channel-scoped tile path.
    for (final channel in SatelliteChannel.values)
      SatelliteMapLayer(
        context.read<Map<SatelliteChannel, SatelliteRepository>>()[channel]!,
        channel: channel,
        referenceOutline: context.read<MapReferenceOutlineController>(),
      ),
    LightningMapLayer(context.read<MeteorLightningRepository>()),
    TyphoonMapLayer(
      context.read<MeteorTyphoonRepository>(),
      radar: context.read<RadarRepository>(),
      satellite: context.read<SatelliteRepository>(),
    ),
    RtsMapLayer(
      context.read<RealtimeNotifier<Rts>>(),
      context.read<TremStationRepository>(),
      eew: context.read<RealtimeNotifier<List<Eew>>>(),
      travelTimeTable: context.read<Future<SeismicTravelTimeTable>>(),
      boxGrid: context.read<Future<RtsBoxGrid>>(),
      townDirectory: context.read<TownDirectory>(),
    ),
    TemperatureMapLayer(context.read<MeteorWeatherRepository>()),
    HumidityMapLayer(context.read<MeteorWeatherRepository>()),
    PressureMapLayer(context.read<MeteorWeatherRepository>()),
    WindMapLayer(context.read<MeteorWeatherRepository>()),
    RainMapLayer(context.read<MeteorRainRepository>()),
    DisasterMapLayer(context.read<DisasterMapRepository>()),
    MeshNodeMapLayer(
      context.read<MeshNodeStore>(),
      service: context.read<MeshtasticService>(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibility = context.watch<MapLayerVisibilityController>();
    // The monitor demo no longer opens straight onto the monitor: speech and
    // its warning sound are scoped to a monitor the user is actually viewing,
    // so demo data must not silently change the active layer.
    final preferred = context.watch<DefaultMapLayerController>().layer;
    // Open on the preferred layer unless it (and only it) is hidden; hidden
    // layers are otherwise offered like any other.
    final initial = _layers.firstWhere(
      (layer) => layer.id == preferred.id && !visibility.isHidden(layer.id),
      orElse: () => _layers.firstWhere(
        (layer) => !visibility.isHidden(layer.id),
        orElse: () => _layers.first,
      ),
    );
    return MapScaffold(
      key: ValueKey(preferred.id),
      layers: _layers,
      initialLayerId: initial.id,
      initialOsmEnabled: initial.id == DefaultMapLayer.dpm.id,
      tabIndex: MapPage.tabIndex,
    );
  }
}
