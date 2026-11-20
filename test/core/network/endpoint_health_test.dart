/// Client-side endpoint health — the judgements the 伺服器狀態 screen renders
/// as the "本機狀態" block.
library;

import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:flutter_test/flutter_test.dart';

const _eew = '/api/v2/eq/eew?sse=1';
const _rts = '/api/v2/trem/rts?sse=1';

void main() {
  test('unknown until a request lands', () {
    final m = EndpointHealthMonitor();
    expect(m.summary, EndpointState.unknown);
    expect(m.entries, isEmpty);
    expect(m.needsAttention, isFalse);
  });

  test('one success → healthy, keyed by hostname without scheme', () {
    final m = EndpointHealthMonitor();
    m.success(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev/path?x=1', _eew);

    final h = m.of(
      EndpointService.eew,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    );
    expect(h, isNotNull);
    expect(h!.host, 'api.lb-tpe1.exptech.dev');
    expect(h.tier, ApiTier.lbApi);
    expect(h.service, EndpointService.eew);
    expect(h.regionCode, 'TPE1');
    expect(h.state, EndpointState.healthy);
    expect(h.lastSuccess, isNotNull);
    expect(h.lastFailure, isNull);
    expect(h.consecutiveFailures, 0);
    expect(m.summary, EndpointState.healthy);
  });

  test('the same host from a bare name is the same entry', () {
    final m = EndpointHealthMonitor();
    m.success(ApiTier.lbApi, 'api.lb-tpe1.exptech.dev', _eew);
    // Feeding a full URL collapses onto the same record.
    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    expect(m.entries, hasLength(1));
  });

  test('one failure → degraded, a second consecutive → down', () {
    final m = EndpointHealthMonitor();
    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    expect(
      m
          .of(EndpointService.eew, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
          .state,
      EndpointState.degraded,
    );
    expect(m.summary, EndpointState.degraded);
    expect(m.needsAttention, isTrue);

    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    expect(
      m
          .of(EndpointService.eew, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
          .state,
      EndpointState.down,
    );
    expect(m.summary, EndpointState.down);
  });

  test('a success clears the failure streak', () {
    final m = EndpointHealthMonitor();
    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    expect(
      m
          .of(EndpointService.eew, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!
          .state,
      EndpointState.down,
    );

    m.success(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    final h = m.of(
      EndpointService.eew,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    )!;
    expect(h.state, EndpointState.healthy);
    expect(h.consecutiveFailures, 0);
    expect(h.lastFailure, isNotNull); // history kept, streak reset
    expect(m.summary, EndpointState.healthy);
    expect(m.needsAttention, isFalse);
  });

  test(
    'summary is down when any host is down, degraded when any is degraded',
    () {
      final m = EndpointHealthMonitor();
      m.success(ApiTier.coreApi, 'https://api.core-tnn1.exptech.dev', _eew);
      m.failure(ApiTier.lbApi, 'https://api.lb-khh1.exptech.dev', _eew);
      expect(m.summary, EndpointState.degraded);
      expect(m.needsAttention, isTrue);

      m.failure(ApiTier.lbApi, 'https://api.lb-khh1.exptech.dev', _eew);
      expect(m.summary, EndpointState.down);
    },
  );

  test('same host on different tiers is tracked separately', () {
    final m = EndpointHealthMonitor();
    // core-tnn1 carries both the redundant coreApi and the exclusive
    // coreExclusiveApi; one failing must not taint the other.
    m.success(ApiTier.coreApi, 'https://api.core-tnn1.exptech.dev', _eew);
    m.failure(
      ApiTier.coreExclusiveApi,
      'https://api.core-tnn1.exptech.dev',
      _eew,
    );

    final core = m.of(
      EndpointService.eew,
      ApiTier.coreApi,
      'api.core-tnn1.exptech.dev',
    )!;
    expect(core.state, EndpointState.healthy);
    final exclusive = m.of(
      EndpointService.eew,
      ApiTier.coreExclusiveApi,
      'api.core-tnn1.exptech.dev',
    )!;
    expect(exclusive.state, EndpointState.degraded);
    // Same hostname, two tiers → two entries.
    expect(m.entries, hasLength(2));
  });

  test('same host on different services is tracked separately', () {
    final m = EndpointHealthMonitor();
    // EEW and RTS both ride lbApi — one failing must not taint the other.
    m.success(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _eew);
    m.failure(ApiTier.lbApi, 'https://api.lb-tpe1.exptech.dev', _rts);

    final eew = m.of(
      EndpointService.eew,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    )!;
    expect(eew.state, EndpointState.healthy);
    final rts = m.of(
      EndpointService.rts,
      ApiTier.lbApi,
      'api.lb-tpe1.exptech.dev',
    )!;
    expect(rts.state, EndpointState.degraded);
    expect(m.entries, hasLength(2));
  });

  test('regionCode derives from the hostname', () {
    final m = EndpointHealthMonitor();
    m.success(
      ApiTier.lbApi,
      'https://api.lb-khh1.exptech.dev',
      '/api/v2/eq/eew',
    );
    expect(
      m
          .of(EndpointService.eew, ApiTier.lbApi, 'api.lb-khh1.exptech.dev')!
          .regionCode,
      'KHH1',
    );
  });

  group('the shared realtime stream', () {
    const host = 'https://api.lb-tpe1.exptech.dev';
    const path = '/api/v1/sse';

    test('feeds both the EEW and the RTS row: its one connection carries '
        'both feeds', () {
      expect(EndpointService.allOfPath(path), [
        EndpointService.eew,
        EndpointService.rts,
      ]);
      // Every other path still names one service.
      expect(EndpointService.allOfPath('/api/v2/eq/eew'), [
        EndpointService.eew,
      ]);

      final m = EndpointHealthMonitor();
      var notified = 0;
      m.addListener(() => notified++);
      m.success(ApiTier.lbApi, host, path);
      expect(notified, 1, reason: 'one outcome, one notification');
      for (final service in [EndpointService.eew, EndpointService.rts]) {
        final h = m.of(service, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!;
        expect(h.state, EndpointState.healthy);
      }
    });

    test('a failure to reach it marks both rows', () {
      final m = EndpointHealthMonitor();
      m
        ..failure(ApiTier.lbApi, host, path)
        ..failure(ApiTier.lbApi, host, path);
      for (final service in [EndpointService.eew, EndpointService.rts]) {
        final h = m.of(service, ApiTier.lbApi, 'api.lb-tpe1.exptech.dev')!;
        expect(h.state, EndpointState.down);
        expect(h.consecutiveFailures, 2);
      }
      expect(m.summary, EndpointState.down);
    });
  });

  test('ofPath follows the families that moved off the exclusive tiers', () {
    // RTS history is v3; the live topic is v2 — both are the RTS service.
    expect(
      EndpointService.ofPath('/api/v3/trem/rts/1783360200'),
      EndpointService.rts,
    );
    expect(EndpointService.ofPath('/api/v2/trem/rts'), EndpointService.rts);
    // The station directory is a static CSV, not an `/api/v1/trem/*` path.
    expect(
      EndpointService.ofPath('/resource/station'),
      EndpointService.tremStation,
    );
    for (final path in [
      '/api/v2/tiles/radar/list',
      '/api/v2/tiles/radar/1783360200/7/1/1.webp',
      '/api/v2/tiles/qpesums/list',
      '/api/v2/tiles/dpm/shelter/10/5/3.mvt',
    ]) {
      expect(
        EndpointService.ofPath(path),
        anyOf(
          EndpointService.radar,
          EndpointService.qpesums,
          EndpointService.dpm,
        ),
      );
    }
  });
}
