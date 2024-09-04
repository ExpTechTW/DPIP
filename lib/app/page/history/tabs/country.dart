import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/app/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/time_convert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class HistoryCountryTab extends StatefulWidget {
  const HistoryCountryTab({super.key});

  @override
  State<HistoryCountryTab> createState() => _HistoryCountryTabState();
}

class _HistoryCountryTabState extends State<HistoryCountryTab> {
  late final locale = Localizations.localeOf(context).toString();
  final list = GlobalKey<RefreshIndicatorState>();
  bool isLoading = true;
  List<History> historyList = [];

  Future<void> refreshHistoryList() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await ExpTech().getHistory();
      if (!mounted) return;
      setState(() {
        historyList = data.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      list.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupBy(historyList, (e) => DateFormat(context.i18n.full_date_format, locale).format(e.time.send));

    return RefreshIndicator(
      key: list,
      onRefresh: refreshHistoryList,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: grouped.isEmpty ? 1 : grouped.length,
        itemBuilder: (context, index) {
          if (grouped.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(context.i18n.home_safety),
              ),
            );
          }

          final key = grouped.keys.elementAt(index);
          final historyGroup = grouped[key]!;

          return Column(children: [
            DateTimelineItem(key),
            ...historyGroup.map((history) {
              final int? expireTimestamp = history.time.expires['all'];
              final TZDateTime expireTimeUTC = convertToTZDateTime(expireTimestamp ?? 0);
              final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
              return HistoryTimelineItem(
                expired: isExpired,
                history: history,
                last: index == historyList.length - 1,
              );
            })
          ]);
        },
      ),
    );
  }
}
