import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';

/// NTP-style server-time fetch — the raw datasource behind [NtpServerTimeSource].
///
/// Time sync is app infrastructure (it feeds the realtime `ServerClock`), not a
/// feature, so it lives in core alongside the rest of the realtime spine.
class NtpApi {
  const NtpApi(this._client);

  final ApiClient _client;

  /// Server time (ms since epoch) with NTP-style round-trip offset correction.
  ///
  /// `https://api-1.exptech.dev/ntp`
  Future<int> serverTimeMs() async {
    final t1 = DateTime.now().microsecondsSinceEpoch;
    final res = await _client.request(
      ApiTier.legacyApi,
      '/ntp',
      options: Options(responseType: ResponseType.plain),
    );
    final t4 = DateTime.now().microsecondsSinceEpoch;

    final t2 = _microsFromHeader(res.headers.value('x-ntp-t2'));
    final t3 = _microsFromHeader(res.headers.value('x-ntp-t3'));
    if (t2 != null && t3 != null) {
      final offset = ((t2 - t1) + (t3 - t4)) / 2;
      return (t3 + offset).toInt() ~/ 1000;
    }
    return double.parse(res.data as String).toInt();
  }

  static int? _microsFromHeader(String? value) =>
      value != null ? (double.parse(value) * 1000).toInt() : null;
}
