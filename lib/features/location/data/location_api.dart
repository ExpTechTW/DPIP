import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Device-location endpoint on the region-aware [ApiClient].
///
/// Migrated from the legacy `api-1` host to `api.core-tnn1`
/// ([ApiTier.coreExclusiveApi]).
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
    '/api/v2/location/$platform/$token/$version/$lat,$lng',
  );
}
