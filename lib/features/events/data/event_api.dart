import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// DPIP disaster-event (事件) endpoints — **API v1**, still on the legacy host.
///
/// Two feeds share the same item shape:
///  - **history** ([getHistoryList] / [getHistoryRegion]) — past notices; the
///    Events tab.
///  - **realtime** ([getRealtimeList] / [getRealtimeRegion]) — currently active
///    notices; the home sheet when collapsed.
///
/// The region form is not a client-side filter of the list — the server decides
/// membership from the event's own `area`/polygon, which the app has no way to
/// evaluate — so 全國 and a township are genuinely different requests.
class EventApi {
  const EventApi(this._client);

  final ApiClient _client;

  /// Not yet migrated to the region topology (see [ApiTier.legacyApi]).
  static const ApiTier _tier = ApiTier.legacyApi;

  /// Nationwide event history, newest first.
  ///
  /// `https://api-1.exptech.dev/api/v1/dpip/history/list`
  Future<List<dynamic>> getHistoryList() async =>
      (await _client.get(_tier, '/api/v1/dpip/history/list') as List?) ??
      const [];

  /// Event history affecting the township [region] (a 3-digit code), newest
  /// first.
  ///
  /// `https://api-1.exptech.dev/api/v1/dpip/history/{region}`
  Future<List<dynamic>> getHistoryRegion(String region) async =>
      (await _client.get(_tier, '/api/v1/dpip/history/$region') as List?) ??
      const [];

  /// Nationwide *active* events, newest first.
  ///
  /// `https://api-1.exptech.dev/api/v1/dpip/realtime/list`
  Future<List<dynamic>> getRealtimeList() async =>
      (await _client.get(_tier, '/api/v1/dpip/realtime/list') as List?) ??
      const [];

  /// Active events affecting the township [region] (a 3-digit code), newest
  /// first.
  ///
  /// `https://api-1.exptech.dev/api/v1/dpip/realtime/{region}`
  Future<List<dynamic>> getRealtimeRegion(String region) async =>
      (await _client.get(_tier, '/api/v1/dpip/realtime/$region') as List?) ??
      const [];
}
