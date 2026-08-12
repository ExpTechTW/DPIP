/// Loads the home header's realtime weather, the township 24h forecast, and the
/// next-hour rain trend.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter/foundation.dart';

/// Fetches nearest-station realtime weather, the township hourly forecast, and
/// the next-hour rain trend for the home sheet, following the selected
/// [RegionStore] township. 全國 has no point weather — [areaCode] is null and
/// all feeds stay cleared. Reloads when the area changes; the last values are
/// kept while a new fetch runs so the sheet never blanks.
///
/// [gpsFix] supplies the live GPS coordinate (nullable when unavailable) for
/// the debug log — the realtime request itself goes to the township centre,
/// so the fix is logged alongside rather than used to fetch.
class HomeWeatherController extends ChangeNotifier {
  HomeWeatherController(
    this._repository,
    this._hourTrendRepository,
    this._regions,
    this._directory, {
    this.gpsFix,
  }) {
    _regions.addListener(_sync);
    _sync();
  }

  final MeteorWeatherRepository _repository;
  final RainHourTrendRepository _hourTrendRepository;
  final RegionStore _regions;
  final TownDirectory _directory;

  /// Live GPS fix for the debug log; null when unavailable.
  final Future<GpsFix?> Function()? gpsFix;

  WeatherRealtime? _weather;
  String? _weatherCode;
  WeatherForecast? _forecast;
  RainHourTrend? _hourTrend;
  bool _loading = false;
  Failure? _failure;
  Failure? _forecastFailure;
  Failure? _hourTrendFailure;
  String? _loadedCode;

  /// The latest realtime observation, or null before the first load / at sea.
  WeatherRealtime? get weather => _weather;

  /// The township code [weather] belongs to — null before the first load. The
  /// header shows readings only when this matches the currently selected area,
  /// so a stale (previous-area) observation never masquerades as the new one
  /// while its fetch runs.
  String? get weatherCode => _weatherCode;

  /// The latest township 24h forecast, or null before the first load / no code.
  WeatherForecast? get forecast => _forecast;

  /// The next-hour per-minute rain trend, or null before the first load /
  /// no code.
  RainHourTrend? get hourTrend => _hourTrend;

  /// Whether a fetch is in flight.
  bool get loading => _loading;

  /// The last realtime failure, if the most recent fetch failed.
  Failure? get failure => _failure;

  /// The last forecast failure, if the most recent forecast fetch failed.
  Failure? get forecastFailure => _forecastFailure;

  /// The last rain-trend failure, if the most recent trend fetch failed.
  Failure? get hourTrendFailure => _hourTrendFailure;

  /// The township code driving the weather. Null for 全國 (no point weather) and
  /// for 所在地 without a GPS fix.
  String? get areaCode => switch (_regions.selected) {
    SavedArea(:final code) => code,
    CurrentArea(:final code) => code,
    NationwideArea() => null,
  };

  /// Re-fetches the current area even though it has not changed — the
  /// pull-to-refresh / tab-reappear entry point.
  Future<void> refresh() async {
    final code = areaCode;
    final town = code == null ? null : _directory.byCode(code);
    if (town == null || code == null) return;
    await _load(code, town.lat, town.lng);
  }

  void _sync() {
    final code = areaCode;
    if (code == _loadedCode) return;
    _loadedCode = code;
    final town = code == null ? null : _directory.byCode(code);
    if (town == null || code == null) {
      _weather = null;
      _weatherCode = null;
      _forecast = null;
      _hourTrend = null;
      _failure = null;
      _forecastFailure = null;
      _hourTrendFailure = null;
      notifyListeners();
      return;
    }
    _load(code, town.lat, town.lng);
  }

  Future<void> _load(String code, double lat, double lng) async {
    _loading = true;
    _failure = null;
    _forecastFailure = null;
    _hourTrendFailure = null;
    notifyListeners();

    // The debug GPS read rides alongside the data fetches, never ahead of
    // them: a fix without a fresh cache sits in its 10s timeout window, and it
    // only annotates the log — awaiting it here would hold the sheet's new
    // readings in limbo for nothing the user can see.
    final gpsFuture = gpsFix?.call();
    final realtimeFuture = _repository.realtime(lat, lng);
    final forecastFuture = _repository.forecast(code);
    final hourTrendFuture = _hourTrendRepository.hourTrend(code);
    final realtime = await realtimeFuture;
    final forecast = await forecastFuture;
    final hourTrend = await hourTrendFuture;
    // Drop a superseded response if the user switched area mid-flight.
    if (_loadedCode != code) return;

    _loading = false;
    realtime.when(
      ok: (value) {
        _weather = value;
        _weatherCode = value == null ? null : code;
        if (value != null) unawaited(_logRealtime(code, gpsFuture, value));
      },
      err: (failure) {
        _failure = failure;
        _weather = null;
        _weatherCode = null;
      },
    );
    forecast.when(
      ok: (value) => _forecast = value,
      err: (failure) {
        _forecastFailure = failure;
        _forecast = null;
      },
    );
    hourTrend.when(
      ok: (value) => _hourTrend = value,
      err: (failure) {
        _hourTrendFailure = failure;
        _hourTrend = null;
      },
    );
    notifyListeners();
  }

  /// Debug line: the GPS fix (3 decimals) plus the nearest-station realtime
  /// result the fetch resolved, for verifying what the device saw. The fix may
  /// still be inside its (up to 10s) timeout window — it only annotates the
  /// log, so it's awaited here, after the sheet has already updated.
  Future<void> _logRealtime(
    String code,
    Future<GpsFix?>? gpsFuture,
    WeatherRealtime value,
  ) async {
    final gps = await gpsFuture;
    final coords = gps == null
        ? 'no-fix'
        : '${gps.lat.toStringAsFixed(3)},${gps.lng.toStringAsFixed(3)}';
    final data = value.data;
    Log.debug(
      // l10n-ignore: debug log line, not user-facing display text
      '所在地 code=$code gps=$coords → '
      '${value.station.name}(${value.station.distance.toStringAsFixed(1)} km) '
      'weather=${data.weather}(${data.weatherCode}) '
      'temp=${data.temperature?.toStringAsFixed(1)}°C '
      'rain=${data.rain?.toStringAsFixed(1)} mm '
      'wind=${data.wind.speed?.toStringAsFixed(1)} m/s',
    );
  }

  @override
  void dispose() {
    _regions.removeListener(_sync);
    super.dispose();
  }
}
