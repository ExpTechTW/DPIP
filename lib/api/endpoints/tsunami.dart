part of '../exptech.dart';

/// Tsunami endpoint methods.
mixin TsunamiEndpoints {
  /// Fetches tsunami data by [id].
  Future<Tsunami> getTsunami(String id) async {
    final res = await _dio.get('${api(1)}/v1/tsunami/$id');
    return Tsunami.fromMap(res.data as Map<String, dynamic>);
  }

  /// Fetches the list of available tsunami event IDs.
  Future<List<String>> getTsunamiList() async {
    final res = await _dio.get('${api(1)}/v1/tsunami/list');
    return (res.data as List).map((e) => e as String).toList();
  }
}
