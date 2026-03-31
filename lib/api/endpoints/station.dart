part of '../exptech.dart';

/// Station and radar endpoint methods.
mixin StationEndpoints {
  /// Fetches the TREM station map, keyed by station ID.
  Future<Map<String, Station>> getStations() async {
    final res = await _cachedDio.get('${api}/v1/trem/station');
    return (res.data as Map<String, dynamic>).map(
      (key, value) =>
          MapEntry(key, Station.fromMap(value as Map<String, dynamic>)),
    );
  }

  /// Fetches the list of available radar timestamps.
  Future<List<String>> getRadarList() async {
    final res = await _cachedDio.get('${api(1)}/v1/tiles/radar/list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  /// Fetches meteor station data for [id].
  Future<MeteorStation> getMeteorStation(String id) async {
    final res = await _dio.get('${api(1)}/v2/meteor/station/$id');
    return MeteorStation.fromMap(res.data as Map<String, dynamic>);
  }
}
