import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/data/eew_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Earthquake providers: the EEW repository and its live realtime feed.
///
/// The realtime channel is built and registered **eagerly** here (not in a lazy
/// provider `create`), because `RealtimeService.startAll()` runs after the first
/// frame and needs every channel already registered on the shared service.
List<SingleChildWidget> earthquakeProviders(SharedDeps deps) {
  final api = EarthquakeApi(deps.apiClient);
  final repository = EewRepositoryImpl(api);
  final channel = RealtimeChannel<List<Eew>>(
    // Live EEW streams over SSE (`/api/v2/eq/eew?sse=1`) behind the source seam;
    // the channel keeps polling this source's buffer, so nothing else changes.
    source: EewRealtimeSource(api.openEewSse),
    clock: deps.serverClock,
    elapsed: SystemElapsed(),
    ticker: const SystemTicker(),
    config: RealtimeConfig.eew,
    label: 'eew',
  );
  deps.realtimeService.register(channel);
  final controller = EewRealtimeController(channel);

  return [
    Provider<EewRepository>.value(value: repository),
    ChangeNotifierProvider<EewRealtimeController>.value(value: controller),
  ];
}
