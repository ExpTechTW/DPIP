part of '../exptech.dart';

/// History, realtime, and event endpoint methods.
mixin HistoryEndpoints {
  /// Fetches the realtime event list.
  Future<List<History>> getRealtime() async {
    final res = await _cachedDio.get('${api(1)}/v1/dpip/realtime/list');
    return (res.data as List).map((e) => History.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the historical event list.
  Future<List<History>> getHistory() async {
    final res = await _cachedDio.get('${api(1)}/v1/dpip/history/list');
    return (res.data as List).map((e) => History.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Fetches realtime events for [region].
  Future<List<History>> getRealtimeRegion(String region) async {
    final res = await _cachedDio.get('${api(1)}/v1/dpip/realtime/$region');
    return (res.data as List).map((e) => History.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Fetches historical events for [region].
  Future<List<History>> getHistoryRegion(String region) async {
    final res = await _cachedDio.get('${api(1)}/v1/dpip/history/$region');
    return (res.data as List).map((e) => History.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Fetches events associated with [id].
  Future<List<History>> getEvent(String id) async {
    final res = await _dio.get('${api(1)}/v1/dpip/event/$id');
    return (res.data as List).map((e) => History.fromMap(e as Map<String, dynamic>)).toList();
  }
}
