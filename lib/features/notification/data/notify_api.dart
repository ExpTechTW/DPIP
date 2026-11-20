/// Notification-settings endpoints on the region-aware [ApiClient].
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';

/// The `notify` endpoints, migrated from the legacy `api-1` host to
/// `api.core-tnn1` ([ApiTier.coreExclusiveApi]). Both return the settings as a
/// flat integer list (one per channel); the repository maps it to a model.
///
/// tnn1 is the **primary**: the tyo1 copy is a hot standby, so a healthy tyo1
/// answers `307` back to tnn1 instead of serving the request itself — settings
/// are written in one place, and the standby only takes traffic while the
/// primary is unavailable. That is why the tier stays exclusive rather than
/// region-redundant: a redundant tier would treat the standby as an equal and
/// split writes across two origins. Dio follows the redirect (its default
/// `followRedirects`), so no request here ever sees the 307 itself, and it never
/// reaches `validateStatus`, which accepts 2xx and 304 only.
class NotifyApi {
  const NotifyApi(this._client);

  final ApiClient _client;

  /// The device's current settings.
  ///
  /// `GET https://api.core-tnn1.exptech.dev/api/v2/notify/{token}`
  Future<List<dynamic>> getNotify(String token) async =>
      (await _client.get(ApiTier.coreExclusiveApi, '${ApiPaths.notify}$token'))
          as List<dynamic>;

  /// Sets one [channel] to option [status]; the server returns the full updated
  /// settings.
  ///
  /// `GET https://api.core-tnn1.exptech.dev/api/v2/notify/{token}/{channel}/{status}`
  Future<List<dynamic>> setNotify(
    String token,
    int channel,
    int status,
  ) async => (await _client.get(
    ApiTier.coreExclusiveApi,
    '${ApiPaths.notify}$token/$channel/$status',
  )) as List<dynamic>;
}
