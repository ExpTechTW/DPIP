/// Loads the home header's current-area realtime weather.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter/foundation.dart';

/// Fetches the nearest-station realtime weather for the home header, following
/// the selected [RegionStore] area (or the current GPS township when the
/// nationwide view is selected). Reloads when the area changes; the last value
/// is kept while a new one loads so the header never blanks.
class HomeWeatherController extends ChangeNotifier {
  HomeWeatherController(this._repository, this._regions, this._directory) {
    _regions.addListener(_sync);
    _sync();
  }

  final MeteorWeatherRepository _repository;
  final RegionStore _regions;
  final TownDirectory _directory;

  WeatherRealtime? _weather;
  bool _loading = false;
  Failure? _failure;
  String? _loadedCode;

  /// The latest realtime observation, or null before the first load / at sea.
  WeatherRealtime? get weather => _weather;

  /// Whether a fetch is in flight.
  bool get loading => _loading;

  /// The last failure, if the most recent fetch failed.
  Failure? get failure => _failure;

  /// The township code driving the weather: the selected saved/current area, or
  /// the GPS township when nationwide is selected.
  String? get _areaCode => switch (_regions.selected) {
    SavedArea(:final code) => code,
    CurrentArea(:final code) => code,
    NationwideArea() => _regions.currentCode,
  };

  void _sync() {
    final code = _areaCode;
    if (code == _loadedCode) return;
    _loadedCode = code;
    final town = code == null ? null : _directory.byCode(code);
    if (town == null) {
      _weather = null;
      notifyListeners();
      return;
    }
    _load(town.lat, town.lng);
  }

  Future<void> _load(double lat, double lng) async {
    _loading = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.realtime(lat, lng);
    _loading = false;
    result.when(
      ok: (value) => _weather = value,
      err: (failure) {
        _failure = failure;
        _weather = null;
      },
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _regions.removeListener(_sync);
    super.dispose();
  }
}
