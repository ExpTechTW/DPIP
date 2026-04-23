/// Provider model for the home page weather data and temporary location override.
library;

import 'dart:async';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
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
  bool _isLoading = false;
  Object? _error;
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

  Future<void> _doRefresh() async {
    final code = _temporaryCode ?? _settingsLocation.code;
    double? lat;
    double? lon;

    if (code != null) {
      final loc = Global.location[code];
      if (loc != null) {
        lat = loc.lat;
        lon = loc.lng;
      }
    }

    lat ??= _settingsLocation.coordinates?.latitude;
    lon ??= _settingsLocation.coordinates?.longitude;

    if (lat == null || lon == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _weather = await Global.api.getWeatherRealtimeByCoords(lat, lon);
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The most recently fetched weather data, or `null` if not yet loaded.
  RealtimeWeather? get weather => _weather;

  /// Whether a weather fetch is currently in progress.
  bool get isLoading => _isLoading;

  /// The error from the last failed fetch, or `null` when the last fetch succeeded.
  Object? get error => _error;

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
