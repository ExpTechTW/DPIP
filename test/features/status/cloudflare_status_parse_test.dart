/// parseCloudflareStatus — keeps only Taipei/Kaohsiung components and maps
/// their states.
library;

import 'package:dpip/features/status/data/cloudflare_status_api.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only taipei and kaohsiung components', () {
    final status = parseCloudflareStatus({
      'page': {'id': 'x'},
      'components': [
        {
          'id': 'a',
          'name': 'Taipei - (TPE)',
          'status': 'operational',
          'updated_at': '2026-08-01T00:00:00.000Z',
        },
        {
          'id': 'b',
          'name': 'Kaohsiung City - (KHH)',
          'status': 'degraded_performance',
          'updated_at': '2026-08-01T00:00:00.000Z',
        },
        {'id': 'c', 'name': 'Tokyo', 'status': 'operational'},
        {'id': 'd', 'name': 'Osaka', 'status': 'operational'},
      ],
    }, at: DateTime.utc(2026, 8, 1, 12));

    expect(status.recordedAt, DateTime.utc(2026, 8, 1, 12));
    expect(status.components.map((c) => c.name), [
      'Taipei - (TPE)',
      'Kaohsiung City - (KHH)',
    ]);
    expect(status.components[0].state, CloudflareComponentState.operational);
    expect(
      status.components[1].state,
      CloudflareComponentState.degradedPerformance,
    );
    expect(status.allOperational, isFalse);
  });

  test('allOperational when every component is operational', () {
    final status = parseCloudflareStatus({
      'components': [
        {
          'name': 'Kaohsiung City - (KHH)',
          'status': 'operational',
          'updated_at': '2026-08-01T00:00:00.000Z',
        },
        {
          'name': 'Taipei - (TPE)',
          'status': 'operational',
          'updated_at': '2026-08-01T00:00:00.000Z',
        },
      ],
    });

    expect(status.allOperational, isTrue);
    // Taipei sorts first regardless of wire order.
    expect(status.components.first.name, 'Taipei - (TPE)');
  });

  test('unknown state and missing body degrade gracefully', () {
    final status = parseCloudflareStatus({
      'components': [
        {
          'name': 'Taipei - (TPE)',
          'status': 'something_else',
          'updated_at': 'not-a-date',
        },
        {'name': 'Tokyo', 'status': 'operational'},
      ],
    });

    expect(status.components, hasLength(1));
    expect(status.components.single.state, CloudflareComponentState.unknown);
    expect(status.allOperational, isFalse);

    final empty = parseCloudflareStatus(null);
    expect(empty.components, isEmpty);
    // No data is not the same as all-clear.
    expect(empty.allOperational, isFalse);
  });
}
