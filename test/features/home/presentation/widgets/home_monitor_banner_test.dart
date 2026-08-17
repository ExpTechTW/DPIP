import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/home/presentation/widgets/home_monitor_banner.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _FakeTicker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) =>
      _NoopHandle();
}

class _NoopHandle implements TickerHandle {
  @override
  void cancel() {}
}

class _StaticSource extends RealtimeSource<List<Eew>> {
  _StaticSource(this.data);
  final List<Eew> data;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(data);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}

Eew _alert() => Eew(
  agency: 'CWA',
  id: 'test',
  serial: 6,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 1786362600000,
    longitude: 121.1,
    latitude: 22.9,
    depth: 10,
    magnitude: 5.1,
    location: '臺東縣',
    max: 4,
  ),
);

Future<RealtimeNotifier<List<Eew>>> _notifier(List<Eew> data) async {
  final channel = RealtimeChannel<List<Eew>>(
    source: _StaticSource(data),
    clock: _FakeClock(DateTime.utc(2026, 8, 12, 12)),
    elapsed: _FakeElapsed(),
    ticker: _FakeTicker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await channel.refreshNow();
  return RealtimeNotifier<List<Eew>>(channel);
}

class _MapTag extends StatelessWidget {
  const _MapTag();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('MAP'));
}

GoRouter _router(Widget home) => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', name: 'home', builder: (_, _) => home),
    GoRoute(path: '/map', name: 'map', builder: (_, _) => const _MapTag()),
  ],
);

Widget _wrap(RealtimeNotifier<List<Eew>> notifier, MapCameraHandoff handoff) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>.value(
          value: notifier,
        ),
        ChangeNotifierProvider<MapCameraHandoff>.value(value: handoff),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: _router(const Scaffold(body: HomeMonitorBanner())),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders nothing while calm — no alert, no tap target', (
    tester,
  ) async {
    final notifier = await _notifier(const []);
    final handoff = MapCameraHandoff();
    await tester.pumpWidget(_wrap(notifier, handoff));

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byType(HomeMonitorBanner),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
    expect(tester.getSize(find.byType(HomeMonitorBanner)), Size.zero);
  });

  testWidgets('shows the active alert and hands off the monitor layer on tap, '
      "styled as an error card", (tester) async {
    final notifier = await _notifier([_alert()]);
    final handoff = MapCameraHandoff();
    await tester.pumpWidget(_wrap(notifier, handoff));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeMonitorBanner)),
    );
    expect(find.text('臺東縣'), findsOneWidget);
    expect(find.text(l10n.eewSerial(6)), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    final colors = Theme.of(tester.element(find.byType(HomeMonitorBanner)))
        .colorScheme;
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(HomeMonitorBanner),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, colors.errorContainer);
    expect(material.elevation, greaterThan(0));

    await tester.tap(find.byType(HomeMonitorBanner));
    await tester.pumpAndSettle();

    // Lands on the map route...
    expect(find.text('MAP'), findsOneWidget);
    // ...having queued the monitor layer for it to pick up.
    final request = handoff.takePending();
    expect(request, isNotNull);
    expect(request!.layerId, 'monitor');
  });
}
