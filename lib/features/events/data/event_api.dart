import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/stale_if_error.dart';
import 'package:dpip/features/events/domain/event_card.dart';

/// DPIP disaster-event cards (事件卡片) — **App API v2**
/// (`/api/v2/dpip/{lang}/…`), on the core hosts.
///
/// Two list feeds share the list shape `{"lang", "cards": [...]}`:
///  - **history** ([history]) — cards still in force or ended within the last
///    3 days; the Events tab.
///  - **realtime** ([realtime]) — cards in force now; the home sheet when
///    collapsed.
///
/// [detail] returns one card's every report, first to latest.
///
/// `{lang}` is one of `eventApiLanguageTags` (`event_language.dart`); the
/// server 404s any other value. `{region}` is a township code as a decimal
/// integer. The region form of a list is not a client-side filter — the server
/// decides membership from the card's own `area` and per-region expiry — so
/// 全國 and a township are genuinely different requests.
///
/// Each method decodes the body through the card model, which throws a
/// [FormatException] on a body of the wrong shape.
class EventApi {
  const EventApi(this._client);

  final ApiClient _client;

  /// Multi-active core (`api.core-{tyo1,tnn1}`), confirmed on the server side:
  /// both regions read the same PostgreSQL, so card ids, bodies and ETags are
  /// byte-identical and an `If-None-Match` saved from one region revalidates
  /// against the other. [ApiClient.request] fails over to the other region on
  /// a 503 (the server's answer when PostgreSQL is unavailable) and on any
  /// other 5xx or transport fault, and throws a 400 or 404 at once.
  static const ApiTier _tier = ApiTier.coreApi;

  static const String _root = '/api/v2/dpip';

  /// Cards in force now or ended within the last 3 days, nationwide or for the
  /// township [region].
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/dpip/{lang}/history[/{region}]`
  ///
  /// Stale-if-error ([ApiClientStaleIfError.getOrSaved]): when every host is
  /// unreachable or answers 5xx, the list saved last time comes back marked as
  /// a saved copy. Past notices stay true; the marker tells the reader newer
  /// ones may be missing.
  Future<Fetched<EventCardList>> history({
    required String lang,
    int? region,
  }) async {
    final fetched = await _client.getOrSaved(
      _tier,
      _listPath(lang, 'history', region),
    );
    return (data: EventCardList.fromJson(fetched.data), stale: fetched.stale);
  }

  /// Cards in force now, nationwide or for the township [region].
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/dpip/{lang}/realtime[/{region}]`
  Future<EventCardList> realtime({required String lang, int? region}) async =>
      EventCardList.fromJson(
        await _client.get(_tier, _listPath(lang, 'realtime', region)),
      );

  /// Every report of card [id], first to latest, with the per-township text
  /// for [region] (`0` for the nationwide text).
  ///
  /// `https://api.core-{tyo1,tnn1}.exptech.dev/api/v2/dpip/{lang}/event/{id}/{region}`
  ///
  /// A card that does not exist answers 404.
  Future<EventCardDetail> detail({
    required String lang,
    required int id,
    required int region,
  }) async => EventCardDetail.fromJson(
    await _client.get(_tier, '$_root/$lang/event/$id/$region'),
  );

  static String _listPath(String lang, String feed, int? region) =>
      region == null ? '$_root/$lang/$feed' : '$_root/$lang/$feed/$region';
}
