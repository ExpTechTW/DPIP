import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';

/// Device-location endpoint on the region-aware [ApiClient].
///
/// Migrated from the legacy `api-1` host to `api.core-tnn1`
/// ([ApiTier.coreExclusiveApi]). tnn1 is the **primary**: the tyo1 copy is a hot
/// standby, so a healthy tyo1 answers `307` back to tnn1 rather than serving the
/// write itself — it takes the traffic only when the primary is gone. That is
/// why the tier stays exclusive instead of becoming region-redundant: there is
/// no second origin to fail over to, only a redirect that names the first one.
/// Dio follows it (the default `followRedirects`), and the redirect never
/// reaches `validateStatus`, which accepts 2xx and 304 only.
class LocationApi {
  const LocationApi(this._client);

  final ApiClient _client;

  /// Reports the device's coordinates for push targeting; the backend resolves
  /// and returns the township. Triggered by **distance moved**, not by the
  /// Home region switch.
  ///
  /// `GET https://api.core-tnn1.exptech.dev/api/v2/location/{platform}/{token}/{version}/{lat},{lng}`
  /// — [platform] is `1` for iOS, `0` for Android.
  Future<dynamic> updateDeviceLocation({
    required int platform,
    required String token,
    required String version,
    required double lat,
    required double lng,
  }) => _client.get(
    ApiTier.coreExclusiveApi,
    '${ApiPaths.location}$platform/$token/$version/$lat,$lng',
  );
}
