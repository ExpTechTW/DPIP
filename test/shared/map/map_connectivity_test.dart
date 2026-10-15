import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/shared/map/map_connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;
  late MapConnectivity connectivity;

  Future<void> Function() forceOnline(String map, {bool fails = false}) =>
      () async {
        calls.add('force $map');
        if (fails) throw StateError('$map is gone');
      };

  setUp(() {
    calls = [];
    connectivity = MapConnectivity(
      setOffline: (offline) async => calls.add('offline=$offline'),
      minRestoreInterval: Duration.zero,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('a new Android map is forced to keep requesting', () async {
    connectivity.attach('a', forceOnline('a'));
    await pumpEventQueue();

    expect(
      calls,
      ['force a'],
      reason:
          'parked requests never reach the tile store, so cached tiles stay '
          'invisible offline',
    );
  });

  test('iOS is left alone — its MapLibre never parks requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    connectivity.attach('a', forceOnline('a'));
    await connectivity.networkRestored();

    expect(calls, isEmpty);
  });

  test('a restored network flips through offline and back on', () async {
    connectivity
      ..attach('a', forceOnline('a'))
      ..attach('b', forceOnline('b'));
    await pumpEventQueue();
    calls.clear();

    await connectivity.networkRestored();

    expect(
      calls,
      ['offline=true', 'force b'],
      reason: 'MapLibre retries what failed on its own offline-to-online edge',
    );
  });

  test('a dead map falls through to a live one', () async {
    connectivity
      ..attach('live', forceOnline('live'))
      ..attach('dead', forceOnline('dead', fails: true));
    await pumpEventQueue();
    calls.clear();

    await connectivity.networkRestored();

    expect(calls, ['offline=true', 'force dead', 'force live']);
  });

  test('with no live map, detection is handed back, never left off', () async {
    connectivity.attach('dead', forceOnline('dead', fails: true));
    await pumpEventQueue();
    calls.clear();

    await connectivity.networkRestored();

    expect(calls, [
      'offline=true',
      'force dead',
      'offline=false',
    ], reason: 'a forced-offline MapLibre would park every request for good');
  });

  test('a detached map is not used', () async {
    connectivity
      ..attach('a', forceOnline('a'))
      ..detach('a');
    calls.clear();

    await connectivity.networkRestored();

    expect(calls, isEmpty, reason: 'no live map, nothing to flip through');
  });

  test('restores are throttled', () async {
    final throttled = MapConnectivity(
      setOffline: (offline) async => calls.add('offline=$offline'),
      minRestoreInterval: const Duration(minutes: 1),
    )..attach('a', forceOnline('a'));
    await pumpEventQueue();
    calls.clear();

    await throttled.networkRestored();
    await throttled.networkRestored();

    expect(calls, ['offline=true', 'force a']);
  });

  test('a host recovering from failures restores the network', () async {
    final health = EndpointHealthMonitor();
    connectivity
      ..attach('a', forceOnline('a'))
      ..watch(health);
    await pumpEventQueue();
    calls.clear();

    const host = 'https://api.lb-tpe1.exptech.dev';
    health.failure(ApiTier.lbApi, host, '/api/v2/eq/eew');
    await pumpEventQueue();
    expect(calls, isEmpty, reason: 'a failure is not a recovery');

    health.success(ApiTier.lbApi, host, '/api/v2/eq/eew');
    await pumpEventQueue();
    expect(calls, ['offline=true', 'force a']);

    calls.clear();
    health.success(ApiTier.lbApi, host, '/api/v2/eq/eew');
    await pumpEventQueue();
    expect(
      calls,
      isEmpty,
      reason: 'a healthy host staying healthy is not news',
    );
  });
}
