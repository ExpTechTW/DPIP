import 'package:dpip/api/model/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/weather_header.dart';
import 'package:dpip/app_old/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app_old/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/time_convert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  bool _isOutOfService = false;
  RealtimeWeather? _weather;
  List<History>? _history;

  void _checkVersion() {
    Preference.version ??= Global.packageInfo.version;
    if (Global.packageInfo.version == Preference.version) return;

    Preference.version = Global.packageInfo.version;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('已更新至 v${Global.packageInfo.version}'),
        action: SnackBarAction(label: context.i18n.update_log, onPressed: () => context.push(ChangelogPage.route)),
        duration: kPersistSnackBar,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    final auto = GlobalProviders.location.auto;
    final code = GlobalProviders.location.codeNotifier.value;
    final location = Global.location[code];

    if (code == null || location == null) {
      if (auto) {
        setState(() => _isOutOfService = true);
      }
      setState(() => _weather = _history = null);
      return;
    }

    setState(() => _isLoading = true);
    _refreshIndicatorKey.currentState?.show();

    try {
      final v = await ExpTech().getWeatherRealtime(code);
      if (!mounted) return;

      setState(() => _weather = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_HomePageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text(context.i18n.get_weather_abnormal)));
    }

    try {
      final v = await ExpTech().getHistoryRegion(code);
      if (!mounted) return;

      setState(() => _history = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_HomePageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text(context.i18n.get_weather_abnormal)));
    }

    if (!mounted) return;

    setState(() => _isOutOfService = false);
    setState(() => _isLoading = false);
  }

  History? get _thunderstorm {
    return _history?.firstWhereOrNull((e) =>
    e.type == 'thunderstorm' && !e.isExpired);
  }

  @override
  void initState() {
    super.initState();

    _checkVersion();

    GlobalProviders.location.codeNotifier.addListener(_refresh);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = 24 + 48 + context.padding.top;
    return Stack(
      children: [
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          edgeOffset: topPadding,
          child: ListView(
            children: [
              SizedBox(height: topPadding),

              // 天氣標頭
              if (_isLoading)
                Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: WeatherHeader.skeleton(context))
              else if (_weather != null)
                Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: WeatherHeader(_weather!))
              else if (_isOutOfService)
                const Padding(padding: EdgeInsets.all(16), child: LocationOutOfServiceCard())
              else
                const Padding(padding: EdgeInsets.all(16), child: LocationNotSetCard()),

              // 即時資訊
              if (!_isLoading && false)
                // TODO(kamiya10): 將監視器地圖的地震資訊移至 ChangeNotifier
                const Padding(padding: EdgeInsets.all(16), child: EewCard()),
              if (!_isLoading && _thunderstorm != null)
                Padding(padding: const EdgeInsets.all(16), child: ThunderstormCard(_thunderstorm!)),

              // 地圖
              const Padding(padding: EdgeInsets.all(16), child: RadarMapCard()),

              // 歷史資訊
              Builder(
                builder: (context) {
                  final history = _history;

                  if (history == null) {
                    return const SizedBox.shrink();
                  }

                  final grouped = groupBy(history, (e) => e.time.send.toLocaleFullDateString(context));

                  return Column(
                    children:
                        grouped.entries.mapIndexed((index, entry) {
                          final date = entry.key;
                          final historyGroup = entry.value;
                          return Column(
                            children: [
                              DateTimelineItem(date, first: index == 0),
                              ...historyGroup.map((item) {
                                final int? expireTimestamp = item.time.expires['all'];
                                final TZDateTime expireTimeUTC = convertToTZDateTime(expireTimestamp ?? 0);
                                final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
                                return HistoryTimelineItem(
                                  expired: isExpired,
                                  history: item,
                                  last: item == history.last,
                                );
                              }),
                            ],
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),

        const Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: SafeArea(child: Align(alignment: Alignment.topCenter, child: LocationButton())),
        ),
      ],
    );
  }

  @override
  void dispose() {
    GlobalProviders.location.codeNotifier.removeListener(_refresh);
    super.dispose();
  }
}
