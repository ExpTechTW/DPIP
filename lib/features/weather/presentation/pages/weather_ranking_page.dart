/// Weather observation ranking — rain / temp / wind / pressure / humidity.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
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
/// - [temperature] ranks **current** `temp` (當下氣溫).
/// - [tempExtremes] ranks recorded daily `hi` / `lo` / `hi−lo` with occurrence
///   times (`hit` / `lot`) and a full analysis line.
/// - Other tabs cover rain / wind / gust / humidity / pressure.
enum WeatherRankingTab {
  rain,
  temperature,
  tempExtremes,
  wind,
  gust,
  humidity,
  pressure;

  static WeatherRankingTab parse(String? raw) => switch (raw) {
    'temperature' || 'temp' => WeatherRankingTab.temperature,
    'tempExtremes' ||
    'extremes' ||
    'tempHigh' ||
    'high' ||
    'tempLow' ||
    'low' ||
    'range' => WeatherRankingTab.tempExtremes,
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
    WeatherRankingTab.tempExtremes => l10n.weatherRankingTempExtremes,
    WeatherRankingTab.wind => l10n.weatherRankingWind,
    WeatherRankingTab.gust => l10n.weatherRankingGust,
    WeatherRankingTab.humidity => l10n.mapLayerHumidity,
    WeatherRankingTab.pressure => l10n.mapLayerPressure,
  };

  IconData get icon => switch (this) {
    WeatherRankingTab.rain => Icons.umbrella_outlined,
    WeatherRankingTab.temperature => Icons.thermostat_outlined,
    WeatherRankingTab.tempExtremes => Icons.thermostat_auto_outlined,
    WeatherRankingTab.wind => Icons.air_outlined,
    WeatherRankingTab.gust => Icons.storm_outlined,
    WeatherRankingTab.humidity => Icons.water_drop_outlined,
    WeatherRankingTab.pressure => Icons.speed_outlined,
  };

  /// Map layer to open when a ranked station is tapped (`MapLayer.id`).
  /// Gust has no dedicated layer — land on wind.
  String get mapLayerId => switch (this) {
    WeatherRankingTab.rain => 'rain',
    WeatherRankingTab.temperature ||
    WeatherRankingTab.tempExtremes => 'temperature',
    WeatherRankingTab.wind || WeatherRankingTab.gust => 'wind',
    WeatherRankingTab.humidity => 'humidity',
    WeatherRankingTab.pressure => 'pressure',
  };
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
  });

  final WeatherRankingTab initialTab;

  @override
  State<WeatherRankingPage> createState() => _WeatherRankingPageState();
}

class _WeatherRankingPageState extends State<WeatherRankingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Result<_RankingData>> _future;
  _RankingData? _loaded;

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
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<Result<_RankingData>> _load() async {
    final weatherRepo = context.read<MeteorWeatherRepository>();
    final rainRepo = context.read<MeteorRainRepository>();

    final weatherStations = await weatherRepo.stations();
    final weatherStationsErr = weatherStations.failureOrNull;
    if (weatherStationsErr != null) return Err(weatherStationsErr);

    final weather = await weatherRepo.latest();
    final weatherErr = weather.failureOrNull;
    if (weatherErr != null) return Err(weatherErr);

    final rainStations = await rainRepo.stations();
    final rainStationsErr = rainStations.failureOrNull;
    if (rainStationsErr != null) return Err(rainStationsErr);

    final rain = await rainRepo.latest();
    final rainErr = rain.failureOrNull;
    if (rainErr != null) return Err(rainErr);

    return Ok(
      _RankingData(
        weatherStations: weatherStations.valueOrNull!,
        weather: weather.valueOrNull!,
        rainStations: rainStations.valueOrNull!,
        rain: rain.valueOrNull!,
      ),
    );
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    await next;
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
    WeatherRankingTab.temperature => _WeatherMetricPanel(
      stations: value.weatherStations,
      snapshot: value.weather,
      valueOf: (o) => o.temperature,
      unit: '°C',
      fractionDigits: 1,
      highLowSort: true,
      mapLayerId: tab.mapLayerId,
      onRefresh: _reload,
    ),
    WeatherRankingTab.tempExtremes => _TempExtremePanel(
      stations: value.weatherStations,
      snapshot: value.weather,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weatherRankingTitle),
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

String _formatSnapshotTime(int unixSeconds) {
  final taipei = DateTime.fromMillisecondsSinceEpoch(
    unixSeconds * 1000,
    isUtc: true,
  ).add(const Duration(hours: 8));
  return DateFormat('yyyy/MM/dd HH:mm').format(taipei);
}

/// Taipei wall-clock `HH:mm` for an occurrence timestamp.
String _formatClock(int unixSeconds) {
  final taipei = DateTime.fromMillisecondsSinceEpoch(
    unixSeconds * 1000,
    isUtc: true,
  ).add(const Duration(hours: 8));
  return DateFormat('HH:mm').format(taipei);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final ranked = rankRain(
      stations: widget.stations,
      snapshot: widget.snapshot,
      interval: _interval,
    );
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
                          icon: Icons.umbrella_outlined,
                          message: l10n.weatherRankingEmpty,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: ranked.length,
                    itemBuilder: (context, index) {
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
    this.highLowSort = false,
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
  final bool highLowSort;
  final bool requirePositive;

  @override
  State<_WeatherMetricPanel> createState() => _WeatherMetricPanelState();
}

class _WeatherMetricPanelState extends State<_WeatherMetricPanel> {
  bool _ascending = false;
  RankingMerge _merge = RankingMerge.none;

  void _setMerge(RankingMerge next) {
    setState(() {
      _merge = _merge == next ? RankingMerge.none : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      widget.highLowSort
                          ? l10n.weatherRankingHighest
                          : l10n.reportFilterOrderDesc,
                    ),
                    selected: !_ascending,
                    onSelected: (_) => setState(() => _ascending = false),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(
                      widget.highLowSort
                          ? l10n.weatherRankingLowest
                          : l10n.reportFilterOrderAsc,
                    ),
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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

/// Daily temperature extremes: rank by recorded high / low / diurnal range.
class _TempExtremePanel extends StatefulWidget {
  const _TempExtremePanel({
    required this.stations,
    required this.snapshot,
    required this.mapLayerId,
    required this.onRefresh,
  });

  final Map<String, WeatherStation> stations;
  final WeatherSnapshot snapshot;
  final String mapLayerId;
  final Future<void> Function() onRefresh;

  @override
  State<_TempExtremePanel> createState() => _TempExtremePanelState();
}

class _TempExtremePanelState extends State<_TempExtremePanel> {
  TempExtremeMetric _metric = TempExtremeMetric.high;
  bool _ascending = false;
  RankingMerge _merge = RankingMerge.none;

  void _setMerge(RankingMerge next) {
    setState(() {
      _merge = _merge == next ? RankingMerge.none : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final ranked = rankTempExtremes(
      stations: widget.stations,
      snapshot: widget.snapshot,
      metric: _metric,
      ascending: _ascending,
      merge: _merge,
    );
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
                for (final metric in TempExtremeMetric.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(switch (metric) {
                        TempExtremeMetric.high =>
                          l10n.weatherRankingExtremeHigh,
                        TempExtremeMetric.low => l10n.weatherRankingExtremeLow,
                        TempExtremeMetric.range =>
                          l10n.weatherRankingExtremeRange,
                      }),
                      selected: _metric == metric,
                      onSelected: (_) => setState(() {
                        _metric = metric;
                        // Low: default coldest-first; high/range: hottest/widest.
                        _ascending = metric == TempExtremeMetric.low;
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
                        // Clock only — no "當下/最高/最低/溫差" dump.
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
