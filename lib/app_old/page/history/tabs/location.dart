import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app_old/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app_old/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/api/model/history.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/time_convert.dart';
import 'package:dpip/widgets/error/region_out_of_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

class HistoryLocationTab extends StatefulWidget {
  const HistoryLocationTab({super.key});

  @override
  State<HistoryLocationTab> createState() => _HistoryLocationTabState();
}

class _HistoryLocationTabState extends State<HistoryLocationTab> {
  late final locale = Localizations.localeOf(context).toString();
  final list = GlobalKey<RefreshIndicatorState>();
  bool isLoading = true;
  List<History> historyList = [];

  Future<void> refreshHistoryList() async {
    setState(() => isLoading = true);

    final code = context.read<SettingsLocationModel>().code;

    if (code == null) return;

    try {
      final data = await ExpTech().getHistoryRegion(code);
      if (!mounted) return;

      setState(() {
        historyList = data.reversed.toList();
        isLoading = false;
      });
    } catch (err) {
      if (!mounted) return;
      TalkerManager.instance.error(err);
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      getSavedLocation();
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      list.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupBy(historyList, (e) => DateFormat(context.i18n.full_date_format, locale).format(e.time.send));

    return Selector<SettingsLocationModel, String?>(
      selector: (context, model) => model.code,
      builder: (context, code, child) {
        if (code == null) {
          return const RegionOutOfService();
        }

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
                  child: Center(child: Text(context.i18n.home_safety)),
                );
              }

              final key = grouped.keys.elementAt(index);
              final historyGroup = grouped[key]!;

              return Column(
                children: [
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
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
