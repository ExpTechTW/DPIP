/// Loads currently active disaster events for the home sheet (collapsed).
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:flutter/foundation.dart';

/// Fetches the *active* (realtime) event feed for the home sheet, following the
/// selected [RegionStore] area. Nationwide / no-GPS uses the national list;
/// a township uses [EventRepository.activeEvents] for that code. Keeps the last
/// list while reloading so the collapsed sheet never blanks.
///
/// The server only lists cards in force; [events] still drops any card that
/// is not [EventCard.isActiveAt] the calibrated now, so a list fetched before
/// a card ended never shows it as active.
class HomeActiveEventsController extends ChangeNotifier {
  HomeActiveEventsController(this._repository, this._regions) {
    _regions.addListener(_sync);
    _sync();
  }

  final EventRepository _repository;
  final RegionStore _regions;

  List<EventCard> _events = const [];
  bool _loading = false;
  Failure? _failure;
  String? _loadedKey;

  /// Cards in force at [AppTime.utc] for the current area, newest first.
  List<EventCard> get events {
    final now = AppTime.utc;
    return [
      for (final card in _events)
        if (card.isActiveAt(now)) card,
    ];
  }

  /// Whether a fetch is in flight.
  bool get loading => _loading;

  /// The last failure, if the most recent fetch failed.
  Failure? get failure => _failure;

  /// The township the list is for; null for the nationwide list. A detail
  /// opened from the list asks for this township's text.
  String? get regionCode => _regions.selectedCode;

  /// Null → nationwide realtime list; otherwise the township code.
  String? get _regionCode => regionCode;

  /// Cache key: distinguishes 全國 (`''`) from a missing GPS township (`null`
  /// CurrentArea) so a locate-then-lose cycle still refetches.
  String get _key {
    final code = _regionCode;
    if (_regions.selected is NationwideArea) return '';
    if (code == null) return 'none';
    return code;
  }

  Future<void> refresh() => _load(_key, _regionCode);

  void _sync() {
    final key = _key;
    if (key == _loadedKey) return;
    _loadedKey = key;
    if (key == 'none') {
      // 所在地 selected but no GPS — nothing local to show; clear rather than
      // silently substituting the national feed, which would read as "these are
      // the events where you are". (Home drops the section entirely in this
      // state and the Events tab shows a notice; this keeps the data honest for
      // whoever reads it.)
      _events = const [];
      _failure = null;
      notifyListeners();
      return;
    }
    _load(key, _regionCode);
  }

  Future<void> _load(String key, String? regionCode) async {
    _loading = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.activeEvents(regionCode: regionCode);
    if (_loadedKey != key) return;
    _loading = false;
    result.when(
      ok: (value) => _events = _newestFirst(value),
      err: (failure) {
        _failure = failure;
        _events = const [];
      },
    );
    notifyListeners();
  }

  /// [cards] (the server's ascending-id order) by send time, newest first;
  /// cards sent at the same instant keep the newer card first.
  static List<EventCard> _newestFirst(List<EventCard> cards) {
    final sorted = [...cards];
    sorted.sort((a, b) {
      final bySend = b.send.compareTo(a.send);
      return bySend != 0 ? bySend : b.id.compareTo(a.id);
    });
    return sorted;
  }

  @override
  void dispose() {
    _regions.removeListener(_sync);
    super.dispose();
  }
}
