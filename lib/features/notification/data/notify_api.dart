/// Notification-settings endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// The `notify` endpoints, migrated from the legacy `api-1` host to
/// `api.core-tnn1` ([ApiTier.coreExclusiveApi]). Both return the settings as a
/// flat integer list (one per channel); the repository maps it to a model.
class NotifyApi {
  const NotifyApi(this._client);

  final ApiClient _client;

  /// The device's current settings.
  ///
  /// `GET https://api.core-tnn1.exptech.dev/api/v2/notify/{token}`
  Future<List<dynamic>> getNotify(String token) async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/api/v2/notify/$token'))
          as List<dynamic>;

  /// Sets one [channel] to option [status]; the server returns the full updated
  /// settings.
  ///
  /// `GET https://api.core-tnn1.exptech.dev/api/v2/notify/{token}/{channel}/{status}`
  Future<List<dynamic>> setNotify(
    String token,
    int channel,
    int status,
  ) async =>
      (await _client.get(
            ApiTier.coreExclusiveApi,
            '/api/v2/notify/$token/$channel/$status',
          ))
          as List<dynamic>;
}
