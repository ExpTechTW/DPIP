/// Paged report catalogue — scroll load-more + explicit search.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:flutter/foundation.dart';

/// Owns the report list's page cursor, draft/applied filters, and load state.
///
/// [draft] is edited in the filter sheet and remembered for the lifetime of the
/// hosting page; [query] is whatever the last [search] / initial load used.
/// Leaving the page disposes this controller and clears both.
class ReportListController extends ChangeNotifier {
  ReportListController(this._repository);

  final ReportRepository _repository;

  static const int pageSize = 30;

  final List<PartialEarthquakeReport> items = [];

  /// Last filters sent to the API.
  ReportListQuery query = ReportListQuery.empty;

  /// In-progress filters from the sheet — not fetched until [search].
  ReportListQuery draft = ReportListQuery.empty;

  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  Failure? _failure;

  bool get hasMore => _hasMore;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  Failure? get failure => _failure;

  /// Set while the rows in [items] are not a current answer, so the page can
  /// say so instead of presenting them as current: the server could not be
  /// reached and they are the copy saved last time, or a refresh failed and
  /// they are what the previous load returned. Null while they are current.
  Staleness? get staleness => _staleness;
  Staleness? _staleness;

  /// When the first page in [items] was last current (calibrated time) — the
  /// age a failed refresh reports for the rows it leaves on screen.
  DateTime? _currentAt;
  bool get isEmpty => !_loading && _failure == null && items.isEmpty;

  /// Draft differs from the last successful / in-flight query.
  bool get hasPendingSearch => draft != query;

  /// Persist sheet edits without hitting the network.
  void setDraft(ReportListQuery value) {
    if (value == draft) return;
    draft = value;
    notifyListeners();
  }

  /// Apply [draft] and fetch page 1.
  Future<void> search() => reload(query: draft);

  /// First page (or re-query). Keeps previous rows until the new page arrives
  /// so a search doesn't flash an empty list.
  Future<void> reload({ReportListQuery? query}) async {
    if (query != null) {
      this.query = query;
      draft = query;
    }
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
    switch (result) {
      case Ok(value: final page, :final stale):
        items
          ..clear()
          ..addAll(page);
        _page = 1;
        _hasMore = page.length >= pageSize;
        _failure = null;
        _staleness = stale;
        _currentAt = stale == null ? AppTime.utc : stale.since;
      case Err(:final failure):
        _failure = failure;
        // The rows stay (see [reload]), but they are no longer current.
        if (items.isNotEmpty) {
          _staleness = Staleness(failure: failure, since: _currentAt);
        }
        Log.warning('Report list reload failed: ${failure.message}');
    }
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
    switch (result) {
      case Ok(value: final page, :final stale):
        items.addAll(page);
        _page = next;
        _hasMore = page.length >= pageSize;
        _failure = null;
        // A saved later page makes the list as a whole a saved copy.
        if (stale != null) _staleness ??= stale;
      case Err(:final failure):
        // Keep existing rows; surface via log — footer can retry loadMore.
        Log.warning('Report list loadMore failed: ${failure.message}');
    }
    _loadingMore = false;
    notifyListeners();
  }
}
