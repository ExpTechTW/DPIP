import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/time_convert.dart';
import 'package:dpip/widget/error/region_out_of_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class HistoryLocationTab extends StatefulWidget {
  const HistoryLocationTab({super.key});

  @override
  State<HistoryLocationTab> createState() => _HistoryLocationTabState();
}

class _HistoryLocationTabState extends State<HistoryLocationTab> {
  final list = GlobalKey<RefreshIndicatorState>();
  bool isLoading = true;
  List<History> historyList = [];

  String? city;
  String? town;
  String? region;

  Future<void> refreshHistoryList() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await ExpTech().getHistoryRegion(region!);
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
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      getSavedLocation();
    }
    final code = Global.preference.getInt("user-code");
    city = Global.location[code.toString()]?.city;
    town = Global.location[code.toString()]?.town;
    region = code?.toString();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      list.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (region == null) {
      return const RegionOutOfService();
    }

    final grouped = groupBy(historyList, (e) => DateFormat(context.i18n.date_format).format(e.time.send));

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
