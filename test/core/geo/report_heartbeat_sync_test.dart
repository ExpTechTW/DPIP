import 'dart:async';

import 'package:dpip/core/geo/location_mode.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/geo/report_heartbeat_sync.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TownDirectory _dir() => TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

/// The reporting point a pinned township resolves to — deliberately not the
/// directory point, so a test can tell which one reached native.
GpsFix _pointFor(Town town) => (lat: town.lat - 0.01, lng: town.lng + 0.01);

/// The native heartbeat reports with no Dart running and never takes a fix, so
/// what it sends is only ever what this handed it: the push token, and the
/// pinned township's point — cleared again on the way back to automatic, or it
/// would keep reporting a township the user has left.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/report_heartbeat');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  ({
    ReportHeartbeatSync sync,
    LocationMode mode,
    StreamController<String> tokens,
  })
  build({
    String? token,
    Map<String, Object> settings = const {},
    Future<void>? pointReady,
  }) {
    final mode = LocationMode(SettingsStore.inMemory({...settings}), _dir());
    final tokens = StreamController<String>.broadcast();
    var current = token;
    tokens.stream.listen((next) => current = next);
    final sync = ReportHeartbeatSync(
      native: BackgroundLocationService(
        platform: 0,
        version: '1.2.3',
        channel: channel,
      ),
      mode: mode,
      manualFix: (town) async {
        await pointReady;
        return _pointFor(town);
      },
      token: () => current,
      tokenChanges: tokens.stream,
    );
    addTearDown(() {
      sync.dispose();
      unawaited(tokens.close());
    });
    return (sync: sync, mode: mode, tokens: tokens);
  }

  List<MethodCall> named(String method) =>
      calls.where((call) => call.method == method).toList();

  test('pushes the stored token on start, and every new one', () async {
    final (:sync, mode: _, :tokens) = build(token: 'first');

    sync.start();
    await sync.settled;
    expect(named('setReportIdentity').single.arguments, {
      'platform': 0,
      'token': 'first',
      'version': '1.2.3',
    });

    tokens.add('second');
    await pumpEventQueue();
    expect(named('setReportIdentity').map((call) => call.arguments['token']), [
      'first',
      'second',
    ]);
  });

  test('a token that arrives after start is still pushed', () async {
    final (:sync, mode: _, :tokens) = build();

    sync.start();
    await sync.settled;
    expect(named('setReportIdentity'), isEmpty);

    tokens.add('late');
    await pumpEventQueue();
    expect(named('setReportIdentity').single.arguments['token'], 'late');
  });

  test('pushes the pinned township point, follows a change, and clears it on '
      'the way back to automatic', () async {
    final (:sync, :mode, tokens: _) = build(token: 'tok');

    // Automatic at start: a point left behind by an earlier pin is cleared.
    sync.start();
    await sync.settled;
    expect(named('clearManualPoint'), hasLength(1));
    expect(named('setManualPoint'), isEmpty);

    final hualien = _dir().byCode('970')!;
    await mode.setManual(hualien);
    await sync.settled;
    final hualienPoint = _pointFor(hualien);
    expect(named('setManualPoint').single.arguments, {
      'lat': hualienPoint.lat,
      'lng': hualienPoint.lng,
    });

    final taipei = _dir().byCode('100')!;
    await mode.setManual(taipei);
    await sync.settled;
    final taipeiPoint = _pointFor(taipei);
    expect(named('setManualPoint').last.arguments, {
      'lat': taipeiPoint.lat,
      'lng': taipeiPoint.lng,
    });

    await mode.setAuto();
    await sync.settled;
    expect(calls.last.method, 'clearManualPoint');
    expect(named('clearManualPoint'), hasLength(2));
  });

  test('a township pinned before launch is pushed on start', () async {
    final (:sync, :mode, tokens: _) = build(
      settings: {SettingKeys.manualLocationTown.name: '970'},
    );
    expect(mode.isManual, isTrue);

    sync.start();
    await sync.settled;

    final point = _pointFor(_dir().byCode('970')!);
    expect(named('setManualPoint').single.arguments, {
      'lat': point.lat,
      'lng': point.lng,
    });
    expect(named('clearManualPoint'), isEmpty);
  });

  test('the last change wins when changes overlap', () async {
    final pointReady = Completer<void>();
    final (:sync, :mode, tokens: _) = build(pointReady: pointReady.future);
    sync.start();
    await sync.settled;
    calls.clear();

    // The pin's point is still being resolved when automatic comes in; it
    // must not land after the clear, or the heartbeat keeps reporting a
    // township the user has left.
    await mode.setManual(_dir().byCode('970')!);
    await pumpEventQueue(); // the pin's push is now waiting on its point
    await mode.setAuto();
    pointReady.complete();
    await sync.settled;

    expect(calls.map((call) => call.method), ['clearManualPoint']);
  });
}
