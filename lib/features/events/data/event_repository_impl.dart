import 'dart:ui' show Locale;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/data/event_language.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_repository.dart';

/// [EventRepository] backed by [EventApi], mapping transport and decode errors
/// (a 404, 410 or 503, a body of the wrong shape) to typed failures via
/// [guardResult] / [guardFetched].
///
/// The `{lang}` of every request is derived from [_locale], read once per
/// request, so a language change applies from the next fetch on.
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._api, {required this._locale});

  final EventApi _api;

  /// The locale the app is showing now.
  final Locale Function() _locale;

  /// The largest `{region}` the server accepts (int32).
  static const int _maxRegion = 0x7fffffff;

  static final RegExp _decimal = RegExp(r'^[0-9]+$');

  @override
  Future<Result<List<EventCard>>> events({String? regionCode}) =>
      guardFetched(() async {
        final fetched = await _api.history(
          lang: _lang(),
          region: _regionOf(regionCode),
        );
        return (data: fetched.data.cards, stale: fetched.stale);
      });

  @override
  Future<Result<List<EventCard>>> activeEvents({String? regionCode}) =>
      guardResult(() async {
        final list = await _api.realtime(
          lang: _lang(),
          region: _regionOf(regionCode),
        );
        return list.cards;
      });

  @override
  Future<Result<EventCardDetail>> detail({
    required int id,
    String? regionCode,
  }) => guardResult(
    () =>
        _api.detail(lang: _lang(), id: id, region: _regionOf(regionCode) ?? 0),
  );

  String _lang() => eventApiLanguage(_locale());

  /// [regionCode] as the API's `{region}`: its decimal value, or null when it
  /// is null or not a plain decimal that fits in an int32 (logged, since the
  /// caller then gets the nationwide answer instead of its township's).
  static int? _regionOf(String? regionCode) {
    if (regionCode == null) return null;
    final value = _decimal.hasMatch(regionCode)
        ? int.tryParse(regionCode)
        : null;
    if (value == null || value > _maxRegion) {
      Log.warning(
        'EventRepository: region code "$regionCode" is not a decimal int32; '
        'using the nationwide request',
      );
      return null;
    }
    return value;
  }
}
