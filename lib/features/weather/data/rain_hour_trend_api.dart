/// Next-hour per-minute rain forecast on the external `exptech.dingbot.tw`
/// host.
library;

import 'package:dpip/core/network/api_client.dart';

/// The `rainforecast` endpoint — the per-township next-hour rain series behind
/// the home-sheet trend card.
///
/// Lives on `exptech.dingbot.tw` (not in the region topology), so it goes
/// through [ApiClient.getAbsolute] rather than a region-pinned [ApiTier]. The
/// `{code}` path segment is the same 3-digit township code as the v5 forecast.
class RainHourTrendApi {
  const RainHourTrendApi(this._client);

  final ApiClient _client;

  /// `https://exptech.dingbot.tw/api/weather/rainforecast/{code}`
  static const String _base =
      'https://exptech.dingbot.tw/api/weather/rainforecast';

  /// The next-hour trend for township [code], as the raw envelope
  /// `{"<series>": [{"start": <sec>, "rain": [60 × mm]}]}`.
  Future<Map<String, dynamic>> getForecast(String code) async =>
      (await _client.getAbsolute('$_base/$code')) as Map<String, dynamic>;
}
