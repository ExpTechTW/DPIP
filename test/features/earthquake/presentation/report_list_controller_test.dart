/// The report list's paging/filter state machine: [search] applies the draft
/// filter sheet, [reload] refetches page 1 without dropping what's on screen
/// while it does, and [loadMore] appends — but the two failure paths are
/// deliberately asymmetric. A [reload] failure still resets `hasMore` to true
/// (so the list looks retryable) and records the failure for an error banner;
/// a [loadMore] failure leaves every flag alone and only logs, so a
/// transient blip on page 3 doesn't blank a screen full of good rows.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/report_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReportRepository implements ReportRepository {
  final List<({int limit, int page, ReportListQuery query})> calls = [];
  Failure? nextError;
  List<PartialEarthquakeReport> nextPage = const [];

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) async {
    calls.add((limit: limit, page: page, query: query));
    final error = nextError;
    if (error != null) return Err(error);
    return Ok(nextPage);
  }

  @override
  Future<Result<EarthquakeReport>> get(String id) => throw UnimplementedError();
}

PartialEarthquakeReport _report(String id) => PartialEarthquakeReport(
  id: id,
  longitude: 121.5,
  latitude: 24.0,
  location: '花蓮縣',
  depth: 10.0,
  magnitude: 5.0,
  intensity: 4,
  time: 1700000000000,
  trem: 0,
  md5: 'abc',
);

List<PartialEarthquakeReport> _page(int count, {String prefix = 'r'}) =>
    List.generate(count, (i) => _report('$prefix$i'));

void main() {
  late _FakeReportRepository repository;
  late ReportListController controller;

  setUp(() {
    repository = _FakeReportRepository();
    controller = ReportListController(repository);
  });

  test('starts empty with no filters applied', () {
    expect(controller.items, isEmpty);
    expect(controller.query, ReportListQuery.empty);
    expect(controller.draft, ReportListQuery.empty);
    expect(controller.hasMore, isTrue);
    expect(controller.isEmpty, isTrue);
  });

  test('setDraft only notifies when the value actually changes', () {
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.setDraft(ReportListQuery.empty);
    expect(notifications, 0);

    const changed = ReportListQuery(minIntensity: 4);
    controller.setDraft(changed);
    expect(notifications, 1);
    expect(controller.draft, changed);
    expect(controller.hasPendingSearch, isTrue);
  });

  test('reload sets loading synchronously before the fetch resolves', () async {
    repository.nextPage = _page(1);

    final future = controller.reload();
    expect(controller.loading, isTrue);
    await future;
    expect(controller.loading, isFalse);
  });

  test('reload replaces items and flags hasMore from a full page', () async {
    repository.nextPage = _page(ReportListController.pageSize);

    await controller.reload();

    expect(controller.items, hasLength(ReportListController.pageSize));
    expect(controller.hasMore, isTrue);
    expect(controller.failure, isNull);
    expect(repository.calls.single.page, 1);
    expect(repository.calls.single.limit, ReportListController.pageSize);
  });

  test('reload flags hasMore false from a short (final) page', () async {
    repository.nextPage = _page(5);

    await controller.reload();

    expect(controller.items, hasLength(5));
    expect(controller.hasMore, isFalse);
  });

  test(
    'search() applies the draft as the new query and fetches page 1',
    () async {
      repository.nextPage = _page(1);
      const draft = ReportListQuery(minIntensity: 5);
      controller.setDraft(draft);

      await controller.search();

      expect(controller.query, draft);
      expect(repository.calls.single.query, draft);
    },
  );

  test('a reload failure keeps stale items, resets hasMore, and records the failure', () async {
    repository.nextPage = _page(3);
    await controller.reload();
    expect(controller.hasMore, isFalse);

    repository.nextError = const NetworkFailure('down');
    await controller.reload();

    expect(controller.items, hasLength(3));
    expect(controller.hasMore, isTrue);
    expect(controller.failure, isA<NetworkFailure>());
    expect(controller.loading, isFalse);
  });

  test('loadMore does nothing once hasMore is false', () async {
    repository.nextPage = _page(3);
    await controller.reload();
    final callsBefore = repository.calls.length;

    await controller.loadMore();

    expect(repository.calls.length, callsBefore);
  });

  test('loadMore appends the next page and advances the cursor', () async {
    repository.nextPage = _page(ReportListController.pageSize, prefix: 'a');
    await controller.reload();

    repository.nextPage = _page(5, prefix: 'b');
    await controller.loadMore();

    expect(controller.items, hasLength(ReportListController.pageSize + 5));
    expect(controller.hasMore, isFalse);
    expect(repository.calls.last.page, 2);
  });

  test('a loadMore failure leaves items and hasMore untouched and does not set failure', () async {
    repository.nextPage = _page(ReportListController.pageSize);
    await controller.reload();
    expect(controller.hasMore, isTrue);
    expect(controller.failure, isNull);

    repository.nextError = const TimeoutFailure('slow');
    await controller.loadMore();

    expect(controller.items, hasLength(ReportListController.pageSize));
    expect(controller.hasMore, isTrue);
    expect(controller.failure, isNull);
    expect(controller.loadingMore, isFalse);
  });

  test('loadMore is a no-op while a reload is already in flight', () async {
    repository.nextPage = _page(ReportListController.pageSize);
    final reloadFuture = controller.reload();
    final callsDuringLoad = repository.calls.length;

    await controller.loadMore();

    expect(repository.calls.length, callsDuringLoad);
    await reloadFuture;
  });
}
