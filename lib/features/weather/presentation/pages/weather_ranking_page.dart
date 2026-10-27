/// Weather observation ranking — rain / temp / wind / pressure / humidity.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/presentation/widgets/ranking_time_sheet.dart';
import 'package:dpip/features/weather/presentation/widgets/weather_ranking_row.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Which metric tab to open (from the Data hub deep-link `?tab=`).
///
/// - [temperature] ranks the reading itself or, through [TempRankMetric], one
///   of the day's recorded extremes (`hi` / `lo` / `hi−lo`) with occurrence
///   times (`hit` / `lot`). The standalone daily-extremes tab was folded in
///   here: two tabs over the same field made it look as though only
///   temperature had extremes.
/// - Other tabs cover rain / wind / gust / humidity / pressure.
enum WeatherRankingTab {
  rain,
  temperature,
  wind,
  gust,
  humidity,
  pressure;

  static WeatherRankingTab parse(String? raw) => switch (raw) {
    'temperature' ||
    'temp' ||
    'tempExtremes' ||
    'extremes' ||
    'tempHigh' ||
    'high' ||
    'tempLow' ||
    'low' ||
    'range' => WeatherRankingTab.temperature,
    'wind' => WeatherRankingTab.wind,
    'gust' => WeatherRankingTab.gust,
    'pressure' || 'pres' => WeatherRankingTab.pressure,
    'humidity' || 'rh' => WeatherRankingTab.humidity,
    _ => WeatherRankingTab.rain,
  };

  /// Deep-link query value (`?tab=`).
  String get query => name;

  String label(AppLocalizations l10n) => switch (this) {
    WeatherRankingTab.rain => l10n.mapLayerRain,
    WeatherRankingTab.temperature => l10n.mapLayerTemperature,
    WeatherRankingTab.wind => l10n.weatherRankingWind,
    WeatherRankingTab.gust => l10n.weatherRankingGust,
    WeatherRankingTab.humidity => l10n.mapLayerHumidity,
    WeatherRankingTab.pressure => l10n.mapLayerPressure,
  };

  IconData get icon => switch (this) {
    WeatherRankingTab.rain => Icons.umbrella_outlined,
    WeatherRankingTab.temperature => Icons.thermostat_outlined,
    WeatherRankingTab.wind => Icons.air_outlined,
    WeatherRankingTab.gust => Icons.storm_outlined,
    WeatherRankingTab.humidity => Icons.water_drop_outlined,
    WeatherRankingTab.pressure => Icons.speed_outlined,
  };

  /// Map layer to open when a ranked station is tapped (`MapLayer.id`).
  /// Gust has no dedicated layer — land on wind.
  String get mapLayerId => switch (this) {
    WeatherRankingTab.rain => 'rain',
    WeatherRankingTab.temperature => 'temperature',
    WeatherRankingTab.wind || WeatherRankingTab.gust => 'wind',
    WeatherRankingTab.humidity => 'humidity',
    WeatherRankingTab.pressure => 'pressure',
  };
}

/// Localised labels for [TempRankMetric] (domain stays Flutter-free).
extension on TempRankMetric {
  String label(AppLocalizations l10n) => switch (this) {
    TempRankMetric.current => l10n.weatherRankingCurrent,
    TempRankMetric.high => l10n.weatherRankingExtremeHigh,
    TempRankMetric.low => l10n.weatherRankingExtremeLow,
    TempRankMetric.range => l10n.weatherRankingExtremeRange,
  };

  /// Coldest-first for the daily low, hottest/widest otherwise.
  bool get ascendingByDefault => this == TempRankMetric.low;
}

/// Localised labels for [RainInterval] (domain stays Flutter-free).
extension on RainInterval {
  String label(AppLocalizations l10n) => switch (this) {
    RainInterval.now => l10n.rainIntervalNow,
    RainInterval.min10 => l10n.rainInterval10m,
    RainInterval.hour1 => l10n.rainInterval1h,
    RainInterval.hour3 => l10n.rainInterval3h,
    RainInterval.hour6 => l10n.rainInterval6h,
    RainInterval.hour12 => l10n.rainInterval12h,
    RainInterval.hour24 => l10n.rainInterval24h,
    RainInterval.day2 => l10n.rainInterval2d,
    RainInterval.day3 => l10n.rainInterval3d,
  };
}

/// Joined catalogues + latest snapshots for ranking.
class _RankingData {
  const _RankingData({
    required this.weatherStations,
    required this.weather,
    required this.rainStations,
    required this.rain,
  });

  final Map<String, WeatherStation> weatherStations;
  final WeatherSnapshot weather;
  final Map<String, WeatherStation> rainStations;
  final RainSnapshot rain;
}

/// Tabbed station ranking under the Data hub.
class WeatherRankingPage extends StatefulWidget {
  const WeatherRankingPage({
    super.key,
    this.initialTab = WeatherRankingTab.rain,
    this.initialTempMetric = TempRankMetric.current,
  });

  final WeatherRankingTab initialTab;

  /// Which temperature figure the temperature tab opens on. The Data hub's
  /// 「溫度極值」 tile lands here with [TempRankMetric.high] instead of opening a
  /// tab of its own.
  final TempRankMetric initialTempMetric;

  @override
  State<WeatherRankingPage> createState() => _WeatherRankingPageState();
}

class _WeatherRankingPageState extends State<WeatherRankingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Result<_RankingData>> _future;
  _RankingData? _loaded;

  /// The chosen historical snapshot, or `null` for the newest one — which is
  /// fetched through `latest()` (not pinned to a timestamp), so a refresh keeps
  /// the default list live instead of freezing it an hour back.
  int? _selectedSecond;

  /// Snapshot times each dataset can still serve, ascending. Empty until the
  /// history endpoints answer — and when they fail, which only costs the
  /// picker: the newest ranking is still worth showing.
  List<int> _weatherTimes = const [];
  List<int> _rainTimes = const [];

  /// Time of the newest weather snapshot last loaded, for the picker's
  /// 「最新」 row. Null until the first load lands.
  int? _latestWeatherTime;

  /// Snapshots already fetched for a chosen time. History snapshots are
  /// immutable and addressed by their second, so re-picking one costs nothing.
  final Map<int, WeatherSnapshot> _weatherAt = {};
  final Map<int, RainSnapshot> _rainAt = {};

  static const _order = WeatherRankingTab.values;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: _order.length,
      vsync: this,
      initialIndex: _order
          .indexOf(widget.initialTab)
          .clamp(0, _order.length - 1),
    );
    _future = _load();
    // Independent of the ranking itself: the list must not wait for a picker
    // that may never be opened.
    _loadHistory().ignore();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<Result<_RankingData>> _load({int? second}) async {
    final weatherRepo = context.read<MeteorWeatherRepository>();
    final rainRepo = context.read<MeteorRainRepository>();

    final weatherStations = await weatherRepo.stations();
    final weatherStationsErr = weatherStations.failureOrNull;
    if (weatherStationsErr != null) return Err(weatherStationsErr);

    final weather = await _weatherSnapshot(weatherRepo, second);
    final weatherErr = weather.failureOrNull;
    if (weatherErr != null) return Err(weatherErr);

    final rainStations = await rainRepo.stations();
    final rainStationsErr = rainStations.failureOrNull;
    if (rainStationsErr != null) return Err(rainStationsErr);

    final rain = await _rainSnapshot(rainRepo, second);
    final rainErr = rain.failureOrNull;
    if (rainErr != null) return Err(rainErr);

    final data = _RankingData(
      weatherStations: weatherStations.valueOrNull!,
      weather: weather.valueOrNull!,
      rainStations: rainStations.valueOrNull!,
      rain: rain.valueOrNull!,
    );
    if (second == null) _latestWeatherTime = data.weather.time;
    return Ok(data);
  }

  /// The weather snapshot for [second]: `latest()` while the list is live,
  /// otherwise the newest history time at or before it.
  Future<Result<WeatherSnapshot>> _weatherSnapshot(
    MeteorWeatherRepository repo,
    int? second,
  ) async {
    if (second == null) return repo.latest();
    final cached = _weatherAt[second];
    if (cached != null) return Ok(cached);
    final resolved = _atOrBefore(_weatherTimes, second);
    // The history has not answered (or is empty): the newest snapshot is the
    // only one this page can honestly draw.
    if (resolved == null) return repo.latest();
    final result = await repo.at(resolved);
    final snapshot = result.valueOrNull;
    if (snapshot != null) _weatherAt[second] = snapshot;
    return result;
  }

  /// The rain counterpart of [_weatherSnapshot] — rain keeps a finer history
  /// (10-minute steps), so the same chosen time usually resolves to its own
  /// nearest snapshot.
  Future<Result<RainSnapshot>> _rainSnapshot(
    MeteorRainRepository repo,
    int? second,
  ) async {
    if (second == null) return repo.latest();
    final cached = _rainAt[second];
    if (cached != null) return Ok(cached);
    final resolved = _atOrBefore(_rainTimes, second);
    if (resolved == null) return repo.latest();
    final result = await repo.at(resolved);
    final snapshot = result.valueOrNull;
    if (snapshot != null) _rainAt[second] = snapshot;
    return result;
  }

  /// The newest time in [times] at or before [second]; the oldest one when
  /// [second] predates everything the history still keeps.
  static int? _atOrBefore(List<int> times, int second) {
    if (times.isEmpty) return null;
    int? best;
    for (final time in times) {
      if (time <= second && (best == null || time > best)) best = time;
    }
    return best ?? times.first;
  }

  /// Loads the snapshot-time lists the picker offers. Failures are logged and
  /// swallowed: the newest ranking does not depend on them, and the next
  /// refresh tries again.
  Future<void> _loadHistory() async {
    final weatherRepo = context.read<MeteorWeatherRepository>();
    final rainRepo = context.read<MeteorRainRepository>();
    final weather = await _timesFrom(weatherRepo.history());
    final rain = await _timesFrom(rainRepo.history());
    if (!mounted) return;
    setState(() {
      _weatherTimes = weather;
      _rainTimes = rain;
    });
  }

  Future<List<int>> _timesFrom(Future<Result<List<int>>> pending) async {
    try {
      final result = await pending;
      final times = result.valueOrNull;
      return times == null ? const <int>[] : (List<int>.of(times)..sort());
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ranking history');
      return const <int>[];
    }
  }

  /// Weather drives the picker: it is the coarser of the two histories, and
  /// every weather tab reads it. Rain alone answers when weather has none.
  List<int> get _pickerTimes =>
      _weatherTimes.isNotEmpty ? _weatherTimes : _rainTimes;

  int? get _newestTime =>
      _latestWeatherTime ??
      (_weatherTimes.isNotEmpty
          ? _weatherTimes.last
          : _rainTimes.isNotEmpty
          ? _rainTimes.last
          : null);

  Future<void> _pickTime() async {
    final times = _pickerTimes;
    final newest = _newestTime;
    if (times.isEmpty || newest == null) return;
    final choice = await showRankingTimeSheet(
      context: context,
      times: times,
      latest: newest,
      selected: _selectedSecond,
    );
    if (!mounted || choice == null) return;
    final second = choice.second;
    if (second == _selectedSecond) return;
    final next = _load(second: second);
    setState(() {
      _selectedSecond = second;
      _future = next;
    });
    // The FutureBuilder owns the outcome; the error surface already shows a
    // failed pick, so awaiting here would only rethrow it into the zone.
    next.ignore();
  }

  Future<void> _reload() async {
    final next = _load(second: _selectedSecond);
    // A block, not an arrow: the assignment expression's value is the future,
    // and `setState` rejects a callback that returns one — in debug that throw
    // lands before the frame is even marked dirty, so pull-to-refresh never
    // rebuilds.
    setState(() {
      _future = next;
    });
    await Future.wait([next, _loadHistory()]);
  }

  Widget _tabsFor(_RankingData value) => TabBarView(
    controller: _tabs,
    children: [
      for (final tab in WeatherRankingTab.values) _panelFor(tab, value),
    ],
  );

  Widget _panelFor(WeatherRankingTab tab, _RankingData value) => switch (tab) {
    WeatherRankingTab.rain => _RainRankingPanel(
      stations: value.rainStations,
      snapshot: value.rain,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.temperature => _TemperaturePanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      initialMetric: widget.initialTempMetric,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.wind => _WeatherMetricPanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      valueOf: (o) => o.windSpeed,
      windDirectionOf: (o) => o.windDirection,
      unit: 'm/s',
      fractionDigits: 1,
      requirePositive: true,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.gust => _WeatherMetricPanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      valueOf: (o) => o.gustSpeed,
      windDirectionOf: (o) => o.gustDirection,
      eventTimeOf: (o) => o.gustTime,
      unit: 'm/s',
      fractionDigits: 1,
      requirePositive: true,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.humidity => _WeatherMetricPanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      valueOf: (o) => o.humidity?.toDouble(),
      unit: '%',
      fractionDigits: 0,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.pressure => _WeatherMetricPanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      valueOf: (o) => o.pressure,
      unit: 'hPa',
      fractionDigits: 1,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedSecond;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weatherRankingTitle),
        actions: [
          if (_pickerTimes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Tooltip(
                message: l10n.weatherRankingPickTime,
                child: TextButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 18),
                  // A past snapshot is not the current weather, so the label
                  // stops saying 「最新」 the moment the user leaves it.
                  label: Text(
                    selected == null
                        ? l10n.weatherRankingLatest
                        : rankingTimeLabel(selected),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            for (final tab in WeatherRankingTab.values)
              Tab(text: tab.label(l10n)),
          ],
        ),
      ),
      body: FutureBuilder<Result<_RankingData>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            final previous = _loaded;
            if (previous != null) return _tabsFor(previous);
            return const LoadingView();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              headline: l10n.commonFetchFailed,
              onRetry: _reload,
            );
          }
          return switch (snapshot.data!) {
            Err() => ErrorView(
              headline: l10n.commonFetchFailed,
              onRetry: _reload,
            ),
            Ok(:final value) => () {
              _loaded = value;
              return _tabsFor(value);
            }(),
          };
        },
      ),
    );
  }
}

final DateFormat _snapshotFormat = DateFormat('yyyy/MM/dd HH:mm');

String _formatSnapshotTime(int unixSeconds) {
  final taipei = AppTime.taipei(
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true),
  );
  return _snapshotFormat.format(taipei);
}

final DateFormat _clockFormat = DateFormat('HH:mm');

/// Taipei wall-clock `HH:mm` for an occurrence timestamp.
String _formatClock(int unixSeconds) {
  final taipei = AppTime.taipei(
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true),
  );
  return _clockFormat.format(taipei);
}

/// Ranking list → map tab: focus camera + open station sheet.
void _openStationOnMap(
  BuildContext context, {
  required String layerId,
  required RankedObservation item,
}) {
  context.read<MapStationHandoff>().request(
    layerId: layerId,
    stationId: item.id,
    latitude: item.station.latitude,
    longitude: item.station.longitude,
  );
  context.goNamed(AppRoutes.map);
}

/// Bottom inset so the last ranked rows aren't hidden by the shell's
/// bottom nav bar (extendBody scaffolds). Same value every nested /data page
/// uses. With `extendBody: true` the bar floats over the page body, so its
/// own height plus the safe-area inset has to be padded away by the list.
double _rankingBottomPad(BuildContext context) =>
    AppSpacing.xl + MediaQuery.paddingOf(context).bottom;

double _fillFraction({
  required List<RankedObservation> ranked,
  required int index,
  required bool ascending,
}) {
  if (ranked.isEmpty) return 0;
  if (ranked.length == 1) return 1;
  final minV = ascending ? ranked.first.value : ranked.last.value;
  final maxV = ascending ? ranked.last.value : ranked.first.value;
  final range = maxV - minV;
  if (range == 0) return 1;
  return (ranked[index].value - minV) / range;
}

/// Chip strip + ranked list for rainfall.
class _RainRankingPanel extends StatefulWidget {
  const _RainRankingPanel({
    required this.stations,
    required this.snapshot,
    required this.mapLayerId,
    required this.onRefresh,
  });

  final Map<String, WeatherStation> stations;
  final RainSnapshot snapshot;
  final String mapLayerId;
  final Future<void> Function() onRefresh;

  @override
  State<_RainRankingPanel> createState() => _RainRankingPanelState();
}

class _RainRankingPanelState extends State<_RainRankingPanel> {
  RainInterval _interval = RainInterval.now;

  /// Same identity cache as [_WeatherMetricPanelState._ranked]: a tab swipe
  /// rebuilds this panel, and sorting every rain gauge again for the same
  /// snapshot is the stutter. A refresh replaces the maps, so identity is
  /// the right key.
  List<RankedObservation>? _rankedCache;
  Map<String, WeatherStation>? _rankedStations;
  RainSnapshot? _rankedSnapshot;
  RainInterval? _rankedInterval;

  List<RankedObservation> _ranked() {
    final cached = _rankedCache;
    if (cached != null &&
        identical(_rankedStations, widget.stations) &&
        identical(_rankedSnapshot, widget.snapshot) &&
        _rankedInterval == _interval) {
      return cached;
    }
    final ranked = rankRain(
      stations: widget.stations,
      snapshot: widget.snapshot,
      interval: _interval,
    );
    _rankedStations = widget.stations;
    _rankedSnapshot = widget.snapshot;
    _rankedInterval = _interval;
    return _rankedCache = ranked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final ranked = _ranked();
    final time = _formatSnapshotTime(widget.snapshot.time);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                for (final option in RainInterval.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(option.label(l10n)),
                      selected: _interval == option,
                      onSelected: (_) => setState(() => _interval = option),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.weatherRankingMeta(time, ranked.length),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                0,
                AppSpacing.xs,
                0,
                _rankingBottomPad(context),
              ),
              // Off-screen gauges are not built. The ranked order and the
              // labels of the rows that are on screen stay the same.
              itemCount: ranked.isEmpty ? 1 : ranked.length,
              itemBuilder: (context, index) {
                if (ranked.isEmpty) {
                  return SizedBox(
                    height: 240,
                    child: EmptyView(
                      icon: Icons.umbrella_outlined,
                      message: l10n.weatherRankingEmpty,
                    ),
                  );
                }
                final item = ranked[index];
                final label = item.value == item.value.roundToDouble()
                    ? '${item.value.toStringAsFixed(0)} mm'
                    : '${item.value.toStringAsFixed(1)} mm';
                return WeatherRankingRow(
                  rank: index + 1,
                  item: item,
                  merge: RankingMerge.none,
                  valueLabel: label,
                  fraction: ranked.first.value == 0
                      ? 0
                      : item.value / ranked.first.value,
                  onTap: () => _openStationOnMap(
                    context,
                    layerId: widget.mapLayerId,
                    item: item,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip strip (sort + merge) + ranked list for a weather metric.
class _WeatherMetricPanel extends StatefulWidget {
  const _WeatherMetricPanel({
    required this.stations,
    required this.snapshot,
    required this.valueOf,
    required this.unit,
    required this.fractionDigits,
    required this.mapLayerId,
    required this.onRefresh,
    this.windDirectionOf,
    this.eventTimeOf,
    this.requirePositive = false,
  });

  final Map<String, WeatherStation> stations;
  final WeatherSnapshot snapshot;
  final double? Function(WeatherObservation o) valueOf;
  final int? Function(WeatherObservation o)? windDirectionOf;
  final int? Function(WeatherObservation o)? eventTimeOf;
  final String unit;
  final int fractionDigits;
  final String mapLayerId;
  final Future<void> Function() onRefresh;
  final bool requirePositive;

  @override
  State<_WeatherMetricPanel> createState() => _WeatherMetricPanelState();
}

class _WeatherMetricPanelState extends State<_WeatherMetricPanel> {
  bool _ascending = false;
  RankingMerge _merge = RankingMerge.none;

  /// The last ranking and the inputs it was computed from (see [_ranked]).
  List<RankedObservation>? _rankedCache;
  Map<String, WeatherStation>? _rankedStations;
  WeatherSnapshot? _rankedSnapshot;
  bool _rankedAscending = false;
  RankingMerge _rankedMerge = RankingMerge.none;

  void _setMerge(RankingMerge next) {
    setState(() {
      _merge = _merge == next ? RankingMerge.none : next;
    });
  }

  /// Ranks the snapshot once per (stations, snapshot, order, merge) — the
  /// page rebuilds this panel on every tab swipe and pull-to-refresh frame,
  /// and re-sorting several hundred stations for the same answer is what
  /// made those stutter. Identity, not equality, for the two maps: a refresh
  /// hands the panel new objects, and anything else hands it the same ones.
  /// The accessor closures are deliberately not keyed on — the parent
  /// creates them anew per build, and each panel sits in a fixed
  /// [TabBarView] slot, so the same State never sees a different metric.
  List<RankedObservation> _ranked() {
    final cached = _rankedCache;
    if (cached != null &&
        identical(_rankedStations, widget.stations) &&
        identical(_rankedSnapshot, widget.snapshot) &&
        _rankedAscending == _ascending &&
        _rankedMerge == _merge) {
      return cached;
    }
    final ranked = rankWeather(
      stations: widget.stations,
      snapshot: widget.snapshot,
      valueOf: widget.valueOf,
      windDirectionOf: widget.windDirectionOf,
      eventTimeOf: widget.eventTimeOf,
      ascending: _ascending,
      merge: _merge,
      requirePositive: widget.requirePositive,
    );
    _rankedStations = widget.stations;
    _rankedSnapshot = widget.snapshot;
    _rankedAscending = _ascending;
    _rankedMerge = _merge;
    return _rankedCache = ranked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final ranked = _ranked();
    final time = _formatSnapshotTime(widget.snapshot.time);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Center(
                    child: Text(
                      l10n.weatherRankingBy,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.reportFilterOrderDesc),
                    selected: !_ascending,
                    onSelected: (_) => setState(() => _ascending = false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.reportFilterOrderAsc),
                    selected: _ascending,
                    onSelected: (_) => setState(() => _ascending = true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: VerticalDivider(
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Center(
                    child: Text(
                      l10n.weatherRankingMergeTo,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.weatherRankingMergeTown),
                    selected: _merge == RankingMerge.town,
                    onSelected: (_) => _setMerge(RankingMerge.town),
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.weatherRankingMergeCounty),
                  selected: _merge == RankingMerge.county,
                  onSelected: (_) => _setMerge(RankingMerge.county),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.weatherRankingMeta(time, ranked.length),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ranked.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 240,
                        child: EmptyView(
                          icon: Icons.inbox_outlined,
                          message: l10n.weatherRankingEmpty,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)
                        .copyWith(bottom: _rankingBottomPad(context)),
                    itemCount: ranked.length,
                    itemBuilder: (context, index) {
                      final item = ranked[index];
                      final valueLabel =
                          '${item.value.toStringAsFixed(widget.fractionDigits)} ${widget.unit}';
                      Widget? windArrow;
                      final dir = item.windDirection;
                      if (dir != null) {
                        // Meteorological "from" → blow-to for Icons.navigation.
                        final radians = degToRad(dir + 180);
                        windArrow = Transform.rotate(
                          angle: radians,
                          child: Icon(
                            Icons.navigation,
                            size: AppSpacing.lg,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        );
                      }
                      return WeatherRankingRow(
                        rank: index + 1,
                        item: item,
                        merge: _merge,
                        valueLabel: valueLabel,
                        fraction: _fillFraction(
                          ranked: ranked,
                          index: index,
                          ascending: _ascending,
                        ),
                        leadingExtra: windArrow,
                        eventTimeLabel: item.eventTime == null
                            ? null
                            : _formatClock(item.eventTime!),
                        onTap: () => _openStationOnMap(
                          context,
                          layerId: widget.mapLayerId,
                          item: item,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Temperature: the reading in the snapshot, or one of the day's recorded
/// extremes (high / low / diurnal range) with its occurrence time.
///
/// The extremes used to be a tab of their own, which read as "only temperature
/// has extremes". They are one field with the reading, so they share one tab
/// and one chip strip.
class _TemperaturePanel extends StatefulWidget {
  const _TemperaturePanel({
    required this.stations,
    required this.snapshot,
    required this.initialMetric,
    required this.mapLayerId,
    required this.onRefresh,
  });

  final Map<String, WeatherStation> stations;
  final WeatherSnapshot snapshot;
  final TempRankMetric initialMetric;
  final String mapLayerId;
  final Future<void> Function() onRefresh;

  @override
  State<_TemperaturePanel> createState() => _TemperaturePanelState();
}

class _TemperaturePanelState extends State<_TemperaturePanel> {
  late TempRankMetric _metric = widget.initialMetric;
  late bool _ascending = widget.initialMetric.ascendingByDefault;
  RankingMerge _merge = RankingMerge.none;

  /// Same identity cache as [_WeatherMetricPanelState._ranked]: a tab swipe
  /// rebuilds this panel, and re-sorting several hundred stations for the same
  /// answer is the stutter.
  List<RankedObservation>? _rankedCache;
  Map<String, WeatherStation>? _rankedStations;
  WeatherSnapshot? _rankedSnapshot;
  TempRankMetric _rankedMetric = TempRankMetric.current;
  bool _rankedAscending = false;
  RankingMerge _rankedMerge = RankingMerge.none;

  void _setMerge(RankingMerge next) {
    setState(() {
      _merge = _merge == next ? RankingMerge.none : next;
    });
  }

  List<RankedObservation> _ranked() {
    final cached = _rankedCache;
    if (cached != null &&
        identical(_rankedStations, widget.stations) &&
        identical(_rankedSnapshot, widget.snapshot) &&
        _rankedMetric == _metric &&
        _rankedAscending == _ascending &&
        _rankedMerge == _merge) {
      return cached;
    }
    final ranked = rankTemperature(
      stations: widget.stations,
      snapshot: widget.snapshot,
      metric: _metric,
      ascending: _ascending,
      merge: _merge,
    );
    _rankedStations = widget.stations;
    _rankedSnapshot = widget.snapshot;
    _rankedMetric = _metric;
    _rankedAscending = _ascending;
    _rankedMerge = _merge;
    return _rankedCache = ranked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final ranked = _ranked();
    final time = _formatSnapshotTime(widget.snapshot.time);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                for (final metric in TempRankMetric.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(metric.label(l10n)),
                      selected: _metric == metric,
                      onSelected: (_) => setState(() {
                        _metric = metric;
                        // Daily low reads coldest-first; everything else reads
                        // hottest / widest first.
                        _ascending = metric.ascendingByDefault;
                      }),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: VerticalDivider(
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.reportFilterOrderDesc),
                    selected: !_ascending,
                    onSelected: (_) => setState(() => _ascending = false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.reportFilterOrderAsc),
                    selected: _ascending,
                    onSelected: (_) => setState(() => _ascending = true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: VerticalDivider(
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Center(
                    child: Text(
                      l10n.weatherRankingMergeTo,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.weatherRankingMergeTown),
                    selected: _merge == RankingMerge.town,
                    onSelected: (_) => _setMerge(RankingMerge.town),
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.weatherRankingMergeCounty),
                  selected: _merge == RankingMerge.county,
                  onSelected: (_) => _setMerge(RankingMerge.county),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.weatherRankingMeta(time, ranked.length),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ranked.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 240,
                        child: EmptyView(
                          icon: Icons.thermostat_auto_outlined,
                          message: l10n.weatherRankingEmpty,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)
                        .copyWith(bottom: _rankingBottomPad(context)),
                    itemCount: ranked.length,
                    itemBuilder: (context, index) {
                      final item = ranked[index];
                      return WeatherRankingRow(
                        rank: index + 1,
                        item: item,
                        merge: _merge,
                        valueLabel: '${item.value.toStringAsFixed(1)} °C',
                        fraction: _fillFraction(
                          ranked: ranked,
                          index: index,
                          ascending: _ascending,
                        ),
                        // Only the extremes happened at a time; the reading
                        // itself is the snapshot's own clock, shown above.
                        eventTimeLabel: item.eventTime == null
                            ? null
                            : _formatClock(item.eventTime!),
                        onTap: () => _openStationOnMap(
                          context,
                          layerId: widget.mapLayerId,
                          item: item,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
