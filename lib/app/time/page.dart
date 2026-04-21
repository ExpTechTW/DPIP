library;

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/app/home/_widgets/date_timeline_item.dart';
import 'package:dpip/app/home/_widgets/history_timeline_item.dart';
import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';

/// 時間頁面 顯示事件時間線
class TimePage extends StatefulWidget {
  /// 創建 [TimePage]。
  const TimePage({super.key});

  @override
  State<TimePage> createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> with WidgetsBindingObserver {
  List<History>? _history;
  HomeMode _currentMode = HomeMode.localActive;
  bool _isLoading = false;
  bool _isOutOfService = false;

  bool _checkIfOutOfService(String? code) {
    if (code == null) return true;
    final auto = GlobalProviders.location.auto;
    final location = Global.location[code];
    return auto && location == null;
  }

  Future<void> _refresh() async {
    if (_isLoading) return;

    final code = GlobalProviders.location.code;
    final isOutOfService = _checkIfOutOfService(code);

    if (isOutOfService && !_currentMode.isNational) {
      _currentMode = _currentMode.isActive ? HomeMode.nationalActive : HomeMode.nationalHistory;
    }

    setState(() {
      _isLoading = true;
      _isOutOfService = isOutOfService;
    });

    await _fetchHistory(code, isOutOfService);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHistory(String? code, bool isOutOfService) async {
    try {
      final shouldUseNational = _currentMode.isNational || isOutOfService || code == null;
      final List<History> history;

      if (shouldUseNational) {
        history = _currentMode.isActive
            ? await ExpTech().getRealtime()
            : await ExpTech().getHistory();
      } else {
        history = _currentMode.isActive
            ? await ExpTech().getRealtimeRegion(code)
            : await ExpTech().getHistoryRegion(code);
      }

      if (mounted) setState(() => _history = history);
    } catch (e, s) {
      if (!mounted) return;
      TalkerManager.instance.error('_TimePageState._fetchHistory', e, s);
      context.scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('取得歷史資訊異常'.i18n)),
      );
    }
  }

  void _onModeChanged(HomeMode mode) {
    setState(() => _currentMode = mode);
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GlobalProviders.location.$code.addListener(_refresh);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalProviders.location.$code.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '時間'.i18n,
                style: context.texts.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            _buildHistoryTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    return ResponsiveContainer(
      child: Builder(
        builder: (context) {
          final history = _history;

          if (history == null || history.isEmpty) {
            return Column(
              children: [
                DateTimelineItem(
                  TZDateTime.now(UTC).toLocaleFullDateString(context),
                  first: true,
                  last: true,
                  mode: _currentMode,
                  onModeChanged: _onModeChanged,
                  isOutOfService: _isOutOfService,
                ),
              ],
            );
          }

          final grouped = groupBy(
            history,
            (e) => e.time.send.toLocaleFullDateString(context),
          );

          return Column(
            children: grouped.entries
                .sorted((a, b) => b.key.compareTo(a.key))
                .mapIndexed(
                  (index, entry) => _buildHistoryGroup(entry, index, history),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildHistoryGroup(
    MapEntry<String, List<History>> entry,
    int index,
    List<History> allHistory,
  ) {
    final historyGroup = entry.value.sorted(
      (a, b) => b.time.send.compareTo(a.time.send),
    );

    return Column(
      children: [
        DateTimelineItem(
          entry.key,
          first: index == 0,
          mode: index == 0 ? _currentMode : null,
          onModeChanged: index == 0 ? _onModeChanged : null,
          isOutOfService: _isOutOfService,
        ),
        ...historyGroup.map((item) {
          return HistoryTimelineItem(
            expired: item.isExpired,
            history: item,
            last: item == allHistory.last,
          );
        }),
      ],
    );
  }
}
