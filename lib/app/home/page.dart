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
import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
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
  List<History>? _realtimeRegion; // 專門用於即時資訊的數據（總是來自 getRealtimeRegion）
  HomeMode _currentMode = HomeMode.localActive;

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

    // 只有所在地模式需要檢查 location
    if (_currentMode.isNational == false && (code == null || location == null)) {
      if (auto) {
        setState(() => _isOutOfService = true);
      }

      setState(() => _weather = _history = null);
      return;
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = false; // 切換到全國模式或有所在地時，重置狀態
      _mapKey = Key('${DateTime.now().millisecondsSinceEpoch}');
    });

    _refreshIndicatorKey.currentState?.show();

    // 天氣資訊總是獲取（不受模式影響）
    if (code != null) {
      try {
        final v = await ExpTech().getWeatherRealtime(code);
        if (!mounted) return;

        setState(() => _weather = v);
      } catch (e, s) {
        if (!mounted) return;

        TalkerManager.instance.error('_HomePageState._refresh', e, s);
        context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得天氣異常'.i18n)));
      }
    } else {
      setState(() => _weather = null);
    }

    // 總是獲取即時資訊數據（用於 EEW 和雷雨卡片）
    if (code != null) {
      try {
        final v = await ExpTech().getRealtimeRegion(code);
        if (!mounted) return;

        setState(() => _realtimeRegion = v);
      } catch (e, s) {
        if (!mounted) return;

        TalkerManager.instance.error('_HomePageState._refresh (realtime)', e, s);
        setState(() => _realtimeRegion = null);
      }
    } else {
      setState(() => _realtimeRegion = null);
    }

    // 根據模式調用對應的 API
    try {
      final List<History> v;
      if (_currentMode.isNational) {
        // 全國模式
        if (_currentMode.isActive) {
          v = await ExpTech().getRealtime(); // 全國生效中
        } else {
          v = await ExpTech().getHistory(); // 全國歷史
        }
      } else {
        // 所在地模式
        if (_currentMode.isActive) {
          v = await ExpTech().getRealtimeRegion(code!); // 所在地生效中
        } else {
          v = await ExpTech().getHistoryRegion(code!); // 所在地歷史
        }
      }

      if (!mounted) return;

      setState(() => _history = v);
    } catch (e, s) {
      if (!mounted) return;

      TalkerManager.instance.error('_HomePageState._refresh', e, s);
      context.scaffoldMessenger.showSnackBar(SnackBar(content: Text('取得歷史資訊異常'.i18n)));
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  History? get _thunderstorm {
    final item =
        _realtimeRegion?.where((e) => e.type == HistoryType.thunderstorm).sorted((a, b) => b.time.send.compareTo(a.time.send)).firstOrNull;
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

              // 即時資訊 - 總是使用 getRealtimeRegion 數據
              if (!_isLoading) ...[
                if (GlobalProviders.data.eew.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: GlobalProviders.data.eew.length,
                    itemBuilder: (context, index) {
                      final data = GlobalProviders.data.eew[index];
                      return Padding(padding: const EdgeInsets.all(16), child: EewCard(data));
                    },
                  ),
                if (_thunderstorm != null)
                  Padding(padding: const EdgeInsets.all(16), child: ThunderstormCard(_thunderstorm!)),
              ],

              // 地圖
              Padding(padding: const EdgeInsets.all(16), child: RadarMapCard(key: _mapKey)),

              // 歷史資訊
              Builder(
                builder: (context) {
                  final history = _history;

                  if (history == null || history.isEmpty) {
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
                              DateTimelineItem(
                                date,
                                first: index == 0,
                                mode: index == 0 ? _currentMode : null,
                                onModeChanged: index == 0
                                    ? (mode) {
                                        setState(() => _currentMode = mode);
                                        _refresh();
                                      }
                                    : null,
                              ),
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
