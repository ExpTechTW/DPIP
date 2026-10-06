/// Two filters that differ by one field must not compare equal. A hash that
/// ignored city or magnitude would let a set collapse distinct catalogue
/// queries into one request.
library;

import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('equality and hash cover every field, including the empty query', () {
    const a = ReportListQuery(
      minIntensity: 1,
      maxIntensity: 7,
      minMagnitude: 3,
      maxMagnitude: 8,
      minDepth: 0,
      maxDepth: 300,
      startTime: '2026-01-01',
      endTime: '2026-01-02',
      sort: 'mag',
      order: 'asc',
      city: '臺北市',
      cityMinInt: 3,
      cityMaxInt: 5,
    );
    const b = ReportListQuery(
      minIntensity: 1,
      maxIntensity: 7,
      minMagnitude: 3,
      maxMagnitude: 8,
      minDepth: 0,
      maxDepth: 300,
      startTime: '2026-01-01',
      endTime: '2026-01-02',
      sort: 'mag',
      order: 'asc',
      city: '臺北市',
      cityMinInt: 3,
      cityMaxInt: 5,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    final collapsed = <ReportListQuery>{};
    collapsed
      ..add(a)
      ..add(b);
    expect(collapsed, hasLength(1));
    expect(a, isNot(ReportListQuery.empty));
    expect(a, isNot(const ReportListQuery(city: '臺北市')));
  });
}
