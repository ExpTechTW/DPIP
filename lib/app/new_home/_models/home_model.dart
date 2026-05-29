/// Provider model for the home page weather data and temporary location override.
library;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Manages weather data and a temporary location override for the home page.
///
/// Pass the app-level [SettingsLocationModel] at construction; the model
/// subscribes to it internally and re-fetches whenever the persisted location
/// changes (unless a temporary override is active).
///
/// Call [setTemporaryCode] to temporarily show weather for a different location.
/// Call [startAutoRefresh] once on page init to begin a 30-minute refresh cycle.
class HomeModel extends ChangeNotifier {
  static const _autoRefreshInterval = Duration(minutes: 30);

  final SettingsLocationModel _settingsLocation;
  String? _temporaryCode;
  RealtimeWeather? _weather;
  List<History> _alerts = const [];
  Map<String, dynamic>? _forecast;
  Timer? _autoRefreshTimer;

  /// Creates a [HomeModel] backed by [settingsLocation].
  ///
  /// Attaches a listener so the model re-fetches automatically when the
  /// persisted location changes.
  HomeModel(this._settingsLocation) {
    _settingsLocation.addListener(_onSettingsLocationChanged);
  }

  void _onSettingsLocationChanged() {
    if (_temporaryCode == null) _doRefresh();
  }

  /// Runs [task] and logs failures under [tag]; returns `null` on error.
  static Future<T?> _safe<T>(String tag, Future<T> Function() task) async {
    try {
      return await task();
    } catch (e) {
      TalkerManager.instance.error('HomeModel $tag', e);
      return null;
    }
  }

  Future<void> _doRefresh() async {
    final code = _temporaryCode ?? _settingsLocation.code;
    final loc = code != null ? Global.location[code] : null;
    final lat = loc?.lat ?? _settingsLocation.coordinates?.latitude;
    final lon = loc?.lng ?? _settingsLocation.coordinates?.longitude;
    if (lat == null || lon == null) return;

    // Fetch weather + alerts + forecast in parallel.
    final results = await Future.wait<Object?>([
      _safe('weather', () => Global.api.getWeatherRealtimeByCoords(lat, lon)),
      if (code != null) _safe('alerts', () => Global.api.getRealtimeRegion(code)) else Future.value(null),
      if (code != null) _safe('forecast', () => Global.api.getWeatherForecast(code)) else Future.value(null),
    ]);

    if (results[0] is RealtimeWeather) _weather = results[0] as RealtimeWeather;
    _alerts = results[1] is List<History>
        ? (results[1]! as List<History>).sorted((a, b) => b.time.send.compareTo(a.time.send))
        : const [];
    if (results[2] is Map<String, dynamic>) _forecast = results[2] as Map<String, dynamic>;
    notifyListeners();
  }

  /// The most recently fetched weather data, or `null` if not yet loaded.
  RealtimeWeather? get weather => _weather;

  /// The most recent realtime alerts for the active location, sorted newest first.
  List<History> get alerts => _alerts;

  /// The most recent thunderstorm alert, or `null` when none active.
  History? get thunderstorm =>
      _alerts.firstWhereOrNull((e) => e.type == HistoryType.thunderstorm);

  /// The 24-hour weather forecast for the active location, or `null` if missing.
  Map<String, dynamic>? get forecast => _forecast;

  /// The currently active temporary location code, or `null` when unset.
  String? get temporaryCode => _temporaryCode;

  /// Temporarily overrides the location to [code] and refreshes weather data.
  ///
  /// Pass `null` to clear the override and revert to the persisted location.
  void setTemporaryCode(String? code) {
    if (_temporaryCode == code) return;
    _temporaryCode = code;
    notifyListeners();
    _doRefresh();
  }

  /// Manually triggers a weather data refresh.
  Future<void> manualRefresh() => _doRefresh();

  /// Starts the 30-minute auto-refresh timer.
  ///
  /// Safe to call multiple times; cancels any existing timer first.
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _doRefresh());
    _doRefresh();
  }

  /// Cancels the auto-refresh timer.
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    _settingsLocation.removeListener(_onSettingsLocationChanged);
    stopAutoRefresh();
    super.dispose();
  }
}

/// Extension on [BuildContext] for ergonomic [HomeModel] access.
extension HomeModelExtension on BuildContext {
  /// Watches [HomeModel] and rebuilds the calling widget when it notifies.
  HomeModel get useHome => watch<HomeModel>();

  /// Reads [HomeModel] without subscribing to updates.
  HomeModel get home => read<HomeModel>();
}
