/// Paged report catalogue — scroll load-more + filter-driven reload.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:flutter/foundation.dart';

/// Owns the report list's page cursor, active [ReportListQuery], and load state.
class ReportListController extends ChangeNotifier {
  ReportListController(this._repository);

  final ReportRepository _repository;

  static const int pageSize = 30;

  final List<PartialEarthquakeReport> items = [];
  ReportListQuery query = ReportListQuery.empty;

  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  Failure? _failure;

  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  Failure? get failure => _failure;
  bool get isEmpty => !_loading && _failure == null && items.isEmpty;

  /// First page (or filter change). Keeps previous rows until the new page
  /// arrives so a filter apply doesn't flash an empty list.
  Future<void> reload({ReportListQuery? query}) async {
    if (query != null) this.query = query;
    if (_loading) return;
    _loading = true;
    _failure = null;
    _hasMore = true;
    _page = 0;
    notifyListeners();

    final result = await _repository.list(
      limit: pageSize,
      page: 1,
      query: this.query,
    );
    result.when(
      ok: (page) {
        items
          ..clear()
          ..addAll(page);
        _page = 1;
        _hasMore = page.length >= pageSize;
        _failure = null;
      },
      err: (failure) {
        _failure = failure;
        Log.warning('Report list reload failed: ${failure.message}');
      },
    );
    _loading = false;
    notifyListeners();
  }

  /// Append the next page when the user scrolls near the bottom.
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();

    final next = _page + 1;
    final result = await _repository.list(
      limit: pageSize,
      page: next,
      query: query,
    );
    result.when(
      ok: (page) {
        items.addAll(page);
        _page = next;
        _hasMore = page.length >= pageSize;
        _failure = null;
      },
      err: (failure) {
        // Keep existing rows; surface via log — footer can retry loadMore.
        Log.warning('Report list loadMore failed: ${failure.message}');
      },
    );
    _loadingMore = false;
    notifyListeners();
  }
}
