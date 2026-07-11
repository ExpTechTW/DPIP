import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// Endpoints **without** multi-active redundancy — served only from
/// `core-tnn1`. There is no failover: if `tnn1` is unavailable, these fail.
///
/// These are the device-/account-stateful services (push registration and
/// per-device notification settings). Methods return raw decoded JSON.
class ExclusiveApi {
  const ExclusiveApi(this._client);

  final ApiClient _client;

  /// Registers/updates this device's location for push targeting.
  ///
  /// [platform] is 1 for iOS, 0 for Android; [version] is the app version.
  Future<dynamic> updateDeviceLocation({
    required String token,
    required int platform,
    required String version,
    required LatLng coordinates,
  }) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }
    return _client.get(
      ApiTier.coreExclusiveApi,
      '/v2/location/$platform/$token/$version/'
      '${coordinates.latitude},${coordinates.longitude}',
    );
  }

  /// Reads this device's notification settings (a list of per-channel ints).
  Future<List<dynamic>> getNotify({required String token}) async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/v2/notify/$token'))
          as List<dynamic>;

  /// Updates a single notification [channel] to [status] and returns the new
  /// settings.
  Future<List<dynamic>> setNotify({
    required String token,
    required int channel,
    required int status,
  }) async {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }
    return (await _client.get(
          ApiTier.coreExclusiveApi,
          '/v2/notify/$token/$channel/$status',
        ))
        as List<dynamic>;
  }

  /// Notification delivery history for this device.
  Future<List<dynamic>> getNotificationHistory() async =>
      (await _client.get(ApiTier.coreExclusiveApi, '/v1/notify/history'))
          as List<dynamic>;
}
