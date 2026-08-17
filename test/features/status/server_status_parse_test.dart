/// The server-status dashboard parsing — every field the page renders flows
/// through here, so a Grafana shape change (a new field ordinal, a missing
/// frame) surfaces here instead of blanking the page silently.
library;

import 'package:dpip/features/status/data/server_status_api.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStatus', () {
    Object? body({
      Object? status,
      Object? errorRate,
      Object? latency,
      Map<String, String>? errorLabels,
      Map<String, String>? latencyLabels,
    }) => {
      'results': {
        'status': {
          'frames': [
            {
              'data': {
                // Grafana returns column-arrays: `values[0]` is the time row,
                // `values[1]` the value row. Instant queries carry one sample.
                'values': [
                  [1720000000000],
                  [status ?? 0],
                ],
              },
              'schema': {
                'fields': [
                  {'name': 'Time'},
                  {'name': 'Value'},
                ],
              },
            },
          ],
        },
        'error_rate_5xx': {
          'frames': [
            {
              'data': {
                'values': [
                  [1720000000000],
                  [errorRate ?? 0],
                ],
              },
              'schema': {
                'fields': [
                  {'name': 'Time'},
                  {
                    'name': 'Value',
                    'labels': errorLabels ?? {'instance': 'lb-tpe1'},
                  },
                ],
              },
            },
          ],
        },
        'avg_latency': {
          'frames': [
            {
              'data': {
                'values': [
                  [1720000000000],
                  [latency ?? 0],
                ],
              },
              'schema': {
                'fields': [
                  {'name': 'Time'},
                  {
                    'name': 'Value',
                    'labels': latencyLabels ?? {'instance': 'lb-tnn1'},
                  },
                ],
              },
            },
          ],
        },
      },
    };

    test('reads all three scalars and the instance labels', () {
      final status = parseStatus(
        body(status: 0, errorRate: 0.05, latency: 23.7),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.down.value, 0);
      expect(status.errorRate.value, closeTo(0.05, 1e-9));
      expect(status.errorRate.instance, 'lb-tpe1');
      expect(status.latency.value, closeTo(23.7, 1e-9));
      expect(status.latency.instance, 'lb-tnn1');
      expect(status.allUp, isTrue);
      expect(status.health, StatusHealth.ok);
    });

    test('a down node flips the health to down', () {
      final status = parseStatus(
        body(status: 2, errorRate: 0, latency: 5),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.allUp, isFalse);
      expect(status.health, StatusHealth.down);
    });

    test('degraded when the error rate is high', () {
      final status = parseStatus(
        body(status: 0, errorRate: 0.2, latency: 5),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.health, StatusHealth.degraded);
    });

    test('degraded when the latency is high', () {
      final status = parseStatus(
        body(status: 0, errorRate: 0, latency: 75),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.health, StatusHealth.degraded);
    });

    test('a missing refId degrades to zeros instead of throwing', () {
      final status = parseStatus({
        'results': <String, Object>{},
      }, at: DateTime.utc(2026, 8, 1, 12));
      expect(status.down.value, 0);
      expect(status.errorRate.value, 0);
      expect(status.latency.value, 0);
      expect(status.health, StatusHealth.ok);
    });

    test('null scalars read as zero', () {
      final status = parseStatus(
        body(status: null, errorRate: null, latency: null),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.down.value, 0);
      expect(status.errorRate.value, 0);
    });

    test('string scalars are parsed numerically', () {
      final status = parseStatus(
        body(status: '1', errorRate: '0.25', latency: '10.5'),
        at: DateTime.utc(2026, 8, 1, 12),
      );
      expect(status.down.value, 1);
      expect(status.errorRate.value, closeTo(0.25, 1e-9));
      expect(status.latency.value, closeTo(10.5, 1e-9));
    });

    test('a body that is not a map throws a format failure', () {
      expect(() => parseStatus('oops'), throwsFormatException);
    });
  });

  test('the dashboard query is a constant, cachable POST body', () {
    // The URL pins the content (same body every call), so the ETag store keys
    // it like an immutable tile. If someone edits the query to take
    // parameters, the caching contract breaks silently.
    final queries = ServerStatusApi.query['queries'] as List<Object?>;
    expect(queries, hasLength(3));
    for (final q in queries.cast<Map<String, Object?>>()) {
      expect(q['instant'], isTrue);
    }
  });
}
