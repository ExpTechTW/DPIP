import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/intervals.dart';
import 'package:dpip/utils/parser.dart';

class RankingPrecipitationTab extends StatefulWidget {
  const RankingPrecipitationTab({super.key});

  @override
  State<RankingPrecipitationTab> createState() => _RankingPrecipitationTabState();
}

class _RankingPrecipitationTabState extends State<RankingPrecipitationTab> {
  Intervals interval = Intervals.now;
  String time = '';
  Map<StationInfo, RainData> data = {};
  List<(StationInfo, double)> ranked = [];

  Future refresh() async {
    final rainTimeList = await ExpTech().getRainList();
    final rainData = await ExpTech().getRain(rainTimeList.last);

    if (!mounted) return;

    data = rainData.asMap().map((_, e) => MapEntry(e.station, e.data));
    time = DateFormat('yyyy/MM/dd HH:mm:ss').format(parseDateTime(rainTimeList.last));
    rank();
  }

  void rank() {
    setState(() {
      ranked = data.entries
          .map((e) {
            double value;
            switch (interval) {
              case Intervals.now:
                value = e.value.now;
              case Intervals.tenMinutes:
                value = e.value.tenMinutes;
              case Intervals.oneHour:
                value = e.value.oneHour;
              case Intervals.threeHours:
                value = e.value.threeHours;
              case Intervals.sixHours:
                value = e.value.sixHours;
              case Intervals.twelveHours:
                value = e.value.twelveHours;
              case Intervals.twentyFourHours:
                value = e.value.twentyFourHours;
              case Intervals.twoDays:
                value = e.value.twoDays;
              case Intervals.threeDays:
                value = e.value.threeDays;
            }
            return (e.key, value);
          })
          .where((e) => e.$2 > 0)
          .sorted((a, b) => (b.$2 - a.$2).sign.toInt());
    });
  }

  void setInterval(Intervals i) {
    interval = i;
    rank();
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('今日'),
                    selected: interval == Intervals.now,
                    onSelected: (value) => setInterval(Intervals.now),
                  ),
                  ChoiceChip(
                    label: const Text('10 分鐘'),
                    selected: interval == Intervals.tenMinutes,
                    onSelected: (value) => setInterval(Intervals.tenMinutes),
                  ),
                  ChoiceChip(
                    label: const Text('1 小時'),
                    selected: interval == Intervals.oneHour,
                    onSelected: (value) => setInterval(Intervals.oneHour),
                  ),
                  ChoiceChip(
                    label: const Text('3 小時'),
                    selected: interval == Intervals.threeHours,
                    onSelected: (value) => setInterval(Intervals.threeHours),
                  ),
                  ChoiceChip(
                    label: const Text('6 小時'),
                    selected: interval == Intervals.sixHours,
                    onSelected: (value) => setInterval(Intervals.sixHours),
                  ),
                  ChoiceChip(
                    label: const Text('12 小時'),
                    selected: interval == Intervals.twelveHours,
                    onSelected: (value) => setInterval(Intervals.twelveHours),
                  ),
                  ChoiceChip(
                    label: const Text('24 小時'),
                    selected: interval == Intervals.twentyFourHours,
                    onSelected: (value) => setInterval(Intervals.twentyFourHours),
                  ),
                  ChoiceChip(
                    label: const Text('2 天'),
                    selected: interval == Intervals.twoDays,
                    onSelected: (value) => setInterval(Intervals.twoDays),
                  ),
                  ChoiceChip(
                    label: const Text('3 天'),
                    selected: interval == Intervals.threeDays,
                    onSelected: (value) => setInterval(Intervals.threeDays),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('資料時間：$time\n共 ${ranked.length} 觀測點',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: ranked.isEmpty ? 1 : ranked.length,
              itemBuilder: (context, index) {
                if (ranked.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = ranked[index];
                final rank = index + 1;

                final backgroundColor =
                    index == 0
                        ? context.theme.extendedColors.amberContainer
                        : index == 1
                        ? context.theme.extendedColors.greyContainer
                        : index == 2
                        ? context.theme.extendedColors.brownContainer
                        : index < 10
                        ? context.colors.surfaceContainerHigh
                        : context.colors.surfaceContainer;

                final foregroundColor =
                    index == 0
                        ? context.theme.extendedColors.onAmberContainer
                        : index == 1
                        ? context.colors.onSurface
                        : index == 2
                        ? context.theme.extendedColors.onBrownContainer
                        : index < 10
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant;

                final iconColor =
                    index == 0
                        ? context.theme.extendedColors.amber
                        : index == 1
                        ? context.theme.extendedColors.grey
                        : context.theme.extendedColors.brown;

                final double fontSize =
                    index == 0
                        ? 20
                        : index < 3
                        ? 18
                        : 16;

                final double iconSize =
                    index == 0
                        ? 32
                        : index == 1
                        ? 28
                        : 24;

                final leading =
                    index < 3
                        ? Icon(
                          index == 0 ? Symbols.trophy_rounded : Symbols.workspace_premium_rounded,
                          color: iconColor,
                          size: iconSize,
                          fill: 1,
                        )
                        : Text('$rank', style: TextStyle(color: foregroundColor, fontSize: fontSize));

                final percentage = item.$2 / ranked.first.$2;

                final location = [
                  Text(
                    item.$1.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight:
                          index == 0
                              ? FontWeight.bold
                              : index < 3
                              ? FontWeight.w500
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.$1.county}${item.$1.town}',
                    style: TextStyle(fontSize: fontSize / 1.25, color: foregroundColor.withValues(alpha: 0.8)),
                  ),
                ];

                final content = [
                  Expanded(
                    child:
                        index < 3
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: location)
                            : Row(children: location),
                  ),
                  Text(
                    '${item.$2} mm',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight:
                          index == 0
                              ? FontWeight.bold
                              : index < 3
                              ? FontWeight.w500
                              : null,
                    ),
                  ),
                ];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 48, child: Center(child: leading)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: backgroundColor,
                            gradient: LinearGradient(
                              colors: [
                                backgroundColor,
                                backgroundColor,
                                backgroundColor.withValues(alpha: 0.4),
                                backgroundColor.withValues(alpha: 0.4),
                              ],
                              stops: [0, percentage, percentage, 1],
                            ),
                          ),
                          child: Row(children: content),
                        ),
                      ),
                    ],
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
