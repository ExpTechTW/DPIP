/// The Flutter-facing seam of the realtime spine: every reachable
/// [AppLifecycleState] transition must land on the one [RealtimeService] hook
/// the wiring promises — resumed drives [RealtimeService.onForeground],
/// inactive drives [RealtimeService.onInterrupted], and hidden/paused both
/// drive [RealtimeService.onBackground] — and disposing the observer must
/// stop forwarding immediately.
///
/// [AppLifecycleListener] itself routes a transition by *both* the new state
/// and the previous one it tracked (independently per listener instance,
/// starting at null): climbing back up from paused passes back through
/// hidden/inactive, but those legs fire `onRestart`/`onShow` instead —
/// callbacks this observer leaves unwired on purpose, since the app has been
/// paused the whole time and only the final resume needs to do anything.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_lifecycle.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServerTimeSource implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(0);
}

ServerClock _throwawayClock() =>
    ServerClock(const SystemClock(), SystemElapsed(), _FakeServerTimeSource());

class _RecordingService extends RealtimeService {
  _RecordingService(super.clock);

  final List<String> calls = [];

  @override
  void onForeground() => calls.add('foreground');

  @override
  void onBackground() => calls.add('background');

  @override
  void onInterrupted() => calls.add('interrupted');
}

void main() {
  testWidgets('each reachable transition lands on its mapped hook', (
    tester,
  ) async {
    final service = _RecordingService(_throwawayClock());
    addTearDown(service.dispose);
    final observer = RealtimeLifecycleObserver(service);
    addTearDown(observer.dispose);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(service.calls, ['foreground']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(service.calls, ['foreground', 'interrupted']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(service.calls, ['foreground', 'interrupted', 'background']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(service.calls, [
      'foreground',
      'interrupted',
      'background',
      'background',
    ]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(service.calls, [
      'foreground',
      'interrupted',
      'background',
      'background',
    ]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(service.calls, [
      'foreground',
      'interrupted',
      'background',
      'background',
      'foreground',
    ]);
  });

  testWidgets('dispose stops forwarding further transitions', (tester) async {
    final service = _RecordingService(_throwawayClock());
    addTearDown(service.dispose);
    final observer = RealtimeLifecycleObserver(service);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(service.calls, ['foreground']);

    observer.dispose();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(service.calls, ['foreground']);
  });
}
