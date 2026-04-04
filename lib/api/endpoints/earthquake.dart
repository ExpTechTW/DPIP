part of '../exptech.dart';

/// Earthquake, EEW, and RTS endpoint methods.
mixin EarthquakeEndpoints {
  /// Fetches a full earthquake report by [reportId].
  Future<EarthquakeReport> getReport(String reportId) async {
    final res = await _dio.get(
      'https://api.core.exptech.dev/api/v2/eq/report/$reportId',
    );
    return EarthquakeReport.fromMap(res.data as Map<String, dynamic>);
  }

  /// Fetches a paginated list of earthquake reports.
  Future<List<PartialEarthquakeReport>> getReportList({
    int? limit = 50,
    int? page = 1,
    int? minIntensity = 0,
    int? maxIntensity = 9,
    int? minMagnitude = 0,
    int? maxMagnitude = 8,
    int? minDepth = 0,
    int? maxDepth = 700,
  }) async {
    final res = await _dio.get(
      'https://api.core.exptech.dev/api/v2/eq/report',
      queryParameters: {'limit': limit, 'page': page},
    );
    return (res.data as List)
        .map((e) => PartialEarthquakeReport.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the latest RTS data, or data at [time] (ms since epoch).
  ///
  /// Throws [Rtsnodata] when [time] is provided but no data exists for that timestamp.
  Future<Rts> getRts([int? time]) async {
    final url = time != null
        ? 'https://api-1.exptech.dev/api/v2/trem/rts/${time ~/ 1000}'
        : '${lb}/v2/trem/rts';
    try {
      final res = await _dio.get(url);
      return Rts.fromMap(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (time != null && e.response?.statusCode == 404) throw const Rtsnodata();
      rethrow;
    }
  }

  /// Fetches the latest EEW list, or data at [time] (ms since epoch).
  Future<List<Eew>> getEew([int? time]) async {
    final url = time != null
        ? 'https://api.core.exptech.dev/api/v2/eq/eew/${time ~/ 1000}'
        : '${lb}/v2/eq/eew';
    final res = await _dio.get(url);
    final eewList = (res.data as List).map(
      (e) => Eew.fromMap(e as Map<String, dynamic>),
    );
    if (Preference.experimentalEewAllSource == true) return eewList.toList();
    return eewList.where((e) => e.agency == 'cwa').toList();
  }
}
