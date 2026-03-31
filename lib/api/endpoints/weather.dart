part of '../exptech.dart';

/// Weather, rain, lightning, and typhoon endpoint methods.
mixin WeatherEndpoints {
  /// Fetches the list of available weather data timestamps.
  Future<List<String>> getWeatherList() async {
    final res = await _dio.get('${api(1)}/v2/meteor/weather/list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  /// Fetches weather station data for [time].
  Future<List<WeatherStation>> getWeather(String time) async {
    final res = await _dio.get('${api(1)}/v2/meteor/weather/$time');
    return (res.data as List)
        .map((e) => WeatherStation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches realtime weather for the nearest station to ([lat], [lon]).
  Future<RealtimeWeather> getWeatherRealtimeByCoords(
    double lat,
    double lon,
  ) async {
    final res = await _cachedDio.get(
      '${api(1)}/v3/weather/realtime/${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
    );
    return RealtimeWeather.fromMap(res.data as Map<String, dynamic>);
  }

  /// Fetches weather forecast data for [region].
  Future<Map<String, dynamic>> getWeatherForecast(String region) async {
    final res = await _cachedDio.get('${api(1)}/v3/weather/forecast/$region');
    return res.data as Map<String, dynamic>;
  }

  /// Fetches the list of available rain data timestamps.
  Future<List<String>> getRainList() async {
    final res = await _dio.get('${api(1)}/v2/meteor/rain/list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  /// Fetches rain station data for [time].
  Future<List<RainStation>> getRain(String time) async {
    final res = await _dio.get('${api(1)}/v2/meteor/rain/$time');
    return (res.data as List)
        .map((e) => RainStation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the list of available typhoon satellite images.
  Future<List> getTyphoonImagesList() async {
    final res = await _dio.get('${api(1)}/v2/meteor/typhoon/images/list');
    return res.data as List;
  }

  /// Fetches the typhoon track GeoJSON.
  Future<Map<String, dynamic>> getTyphoonGeojson() async {
    final res = await _dio.get('${api(1)}/v2/meteor/typhoon/geojson');
    return res.data as Map<String, dynamic>;
  }

  /// Fetches the list of available lightning data timestamps.
  Future<List<String>> getLightningList() async {
    final res = await _dio.get('${api(1)}/v2/meteor/lightning/list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  /// Fetches lightning strike data for [time].
  Future<List<Lightning>> getLightning(String time) async {
    final res = await _dio.get('${api(1)}/v2/meteor/lightning/$time');
    return (res.data as List)
        .map((e) => Lightning.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
