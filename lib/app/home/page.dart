import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/changelog/page.dart';
import 'package:dpip/app/home/_widgets/date_timeline_item.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/location_not_set_card.dart';
import 'package:dpip/app/home/_widgets/location_out_of_service.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/thunderstorm_card.dart';
import 'package:dpip/app/home/_widgets/weather_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/time_convert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  Key? _mapKey;

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
        content: Text('已更新至 {version}'.i18n.args({'version': 'v${Global.packageInfo.version}'})),
        action: SnackBarAction(label: '更新日誌'.i18n, onPressed: () => context.push(ChangelogPage.route)),
        duration: kPersistSnackBar,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    final auto = GlobalProviders.location.auto;
    final code = GlobalProviders.location.code;
    final location = Global.location[code];

    if (code == null || location == null) {
      if (auto) {
        setState(() => _isOutOfService = true);
      }

      setState(() => _weather = _history = null);
      return;
    }

    setState(() {
      _isLoading = true;
      _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
    });

    _refreshIndicatorKey.currentState?.show();

    try {
      final v = await ExpTech().getWeatherRealtime(code);
      if (!mounted) return;

      setState(() => _weather = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_HomePageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得天氣異常'.i18n)));
    }

    try {
      final v = await ExpTech().getHistoryRegion(code);
      if (!mounted) return;

      setState(() => _history = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_HomePageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得天氣異常'.i18n)));
    }

    if (!mounted) return;

    setState(() {
      _isOutOfService = false;
      _isLoading = false;
    });
  }

  History? get _thunderstorm {
    final item =
        _history
            ?.where((e) => e.type == HistoryType.thunderstorm && !e.isExpired)
            .sorted((a, b) => b.time.send.compareTo(a.time.send))
            .firstOrNull;
    return item;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion());
    GlobalProviders.location.$code.addListener(_refresh);
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
              if (!_isLoading && GlobalProviders.data.eew.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: GlobalProviders.data.eew.length,
                  itemBuilder: (context, index) {
                    final data = GlobalProviders.data.eew[index];
                    return Padding(padding: const EdgeInsets.all(16), child: EewCard(data));
                  },
                ),
              if (!_isLoading && _thunderstorm != null)
                Padding(padding: const EdgeInsets.all(16), child: ThunderstormCard(_thunderstorm!)),

              // 地圖
              Padding(padding: const EdgeInsets.all(16), child: RadarMapCard(key: _mapKey)),

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
                        grouped.entries.sorted((a, b) => b.key.compareTo(a.key)).mapIndexed((index, entry) {
                          final date = entry.key;
                          final historyGroup = entry.value.sorted((a, b) => b.time.send.compareTo(a.time.send));
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
    GlobalProviders.location.$code.removeListener(_refresh);
    super.dispose();
  }
}
