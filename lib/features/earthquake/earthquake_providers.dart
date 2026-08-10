import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/data/eew_repository_impl.dart';
import 'package:dpip/features/earthquake/data/rts_box_grid_source.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:dpip/features/earthquake/data/trem_station_repository_impl.dart';
import 'package:dpip/features/earthquake/data/report_repository_impl.dart';
import 'package:dpip/features/earthquake/data/seismic_travel_time_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Earthquake providers: the EEW repository, report catalogue, and the live
/// EEW + RTS realtime feeds (SSE behind the `RealtimeSource` seam).
///
/// Each realtime channel is built and registered **eagerly** here (not in a lazy
/// provider `create`), because `RealtimeService.startAll()` runs after the first
/// frame and needs every channel already registered on the shared service.
List<SingleChildWidget> earthquakeProviders(SharedDeps deps) {
  final api = EarthquakeApi(deps.apiClient);
  final repository = EewRepositoryImpl(api);
  final reports = ReportRepositoryImpl(api);

  // Live EEW over SSE (`/api/v2/eq/eew?sse=1`) — bursty, connection-open liveness.
  final eewChannel = RealtimeChannel<List<Eew>>(
    source: EewRealtimeSource(api.openEewSse),
    clock: deps.serverClock,
    elapsed: SystemElapsed(),
    ticker: const SystemTicker(),
    config: RealtimeConfig.eew,
    label: 'eew',
  );
  deps.realtimeService.register(eewChannel);
  final eewController = EewRealtimeController(eewChannel);

  // Live RTS over SSE (`/api/v2/trem/rts?sse=1`) — continuous ~1 Hz; the source
  // uses event-recency liveness, so a silent-but-open link ages to stale.
  final rtsChannel = RealtimeChannel<Rts>(
    source: RtsRealtimeSource(api.openRtsSse),
    clock: deps.serverClock,
    elapsed: SystemElapsed(),
    ticker: const SystemTicker(),
    config: RealtimeConfig.rts,
    label: 'rts',
  );
  deps.realtimeService.register(rtsChannel);
  final rtsController = RtsRealtimeController(rtsChannel);

  // Bundled CWA P/S travel-time table (asset load, not network) — loaded once
  // here and shared as a `Future` (mirrors `Future<TownBoundaries>` in
  // `core_providers.dart`) so a consumer just awaits it, no repeated I/O.
  final travelTimeTable = const SeismicTravelTimeSource().load();

  // Bundled RTS box grid (asset load, not network) — same `Future` pattern.
  final boxGrid = const RtsBoxGridSource().load();

  return [
    Provider<EewRepository>.value(value: repository),
    Provider<ReportRepository>.value(value: reports),
    ChangeNotifierProvider<EewRealtimeController>.value(value: eewController),
    ChangeNotifierProvider<RtsRealtimeController>.value(value: rtsController),
    // The RTS feed under its core supertype + the seismic station directory, so
    // the map's RTS layer can consume both without importing this feature.
    // ChangeNotifierProvider (not Provider) because RealtimeNotifier is a
    // Listenable — a plain Provider throws the invalid-value-type check.
    ChangeNotifierProvider<RealtimeNotifier<Rts>>.value(value: rtsController),
    Provider<Future<SeismicTravelTimeTable>>.value(value: travelTimeTable),
    Provider<Future<RtsBoxGrid>>.value(value: boxGrid),
    Provider<TremStationRepository>.value(
      value: TremStationRepositoryImpl(deps.apiClient),
    ),
  ];
}
