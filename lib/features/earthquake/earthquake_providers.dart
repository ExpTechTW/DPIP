import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/data/eew_repository_impl.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Earthquake providers: the EEW repository and the live EEW + RTS realtime
/// feeds, both streaming over SSE behind the `RealtimeSource` seam.
///
/// Each realtime channel is built and registered **eagerly** here (not in a lazy
/// provider `create`), because `RealtimeService.startAll()` runs after the first
/// frame and needs every channel already registered on the shared service.
List<SingleChildWidget> earthquakeProviders(SharedDeps deps) {
  final api = EarthquakeApi(deps.apiClient);
  final repository = EewRepositoryImpl(api);

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

  return [
    Provider<EewRepository>.value(value: repository),
    ChangeNotifierProvider<EewRealtimeController>.value(value: eewController),
    ChangeNotifierProvider<RtsRealtimeController>.value(value: rtsController),
  ];
}
