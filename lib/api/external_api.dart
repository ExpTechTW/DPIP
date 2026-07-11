import 'package:dio/dio.dart';

/// Third-party endpoints that are not part of the ExpTech region topology
/// (GitHub, Crowdin, the status page). They use fixed external hosts, so they
/// are neither region-selected nor failed over.
///
/// Methods return raw decoded JSON; callers decide how to surface errors.
class ExternalApi {
  const ExternalApi(this._dio);

  final Dio _dio;

  /// Crowdin localization progress (via the ExpTech proxy).
  ///
  /// `https://exptech.dev/api/v1/dpip/locale`
  Future<dynamic> getLocalizationProgress() async {
    final res = await _dio.get('https://exptech.dev/api/v1/dpip/locale');
    return res.data['data'];
  }

  /// GitHub release notes for DPIP Pocket.
  ///
  /// `https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases`
  Future<List<dynamic>> getReleases() async {
    final res = await _dio.get(
      'https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases',
    );
    return res.data as List<dynamic>;
  }

  /// Service status for the past day.
  ///
  /// `https://status.exptech.dev/api/v1/status/data?duration=1d`
  Future<List<dynamic>> getStatus() async {
    final res = await _dio.get(
      'https://status.exptech.dev/api/v1/status/data',
      queryParameters: {'duration': '1d'},
    );
    return res.data as List<dynamic>;
  }
}
