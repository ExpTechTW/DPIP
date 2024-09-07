import 'package:collection/collection.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/util/intervals.dart';
import 'package:dpip/util/parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/weather/rain.dart';

class RankingPrecipitationTab extends StatefulWidget {
  const RankingPrecipitationTab({super.key});

  @override
  State<RankingPrecipitationTab> createState() => _RankingPrecipitationTabState();
}

class _RankingPrecipitationTabState extends State<RankingPrecipitationTab> {
  Intervals interval = Intervals.now;
  String time = "";
  Map<StationInfo, RainData> data = {};
  List<(StationInfo, double)> ranked = [];

  Future refresh() async {
    final rainTimeList = await ExpTech().getRainList();
    final rainData = await ExpTech().getRain(rainTimeList.last);

    if (!mounted) return;

    data = rainData.asMap().map((_, e) => MapEntry(e.station, e.data));
    time = DateFormat(context.i18n.datetime_format).format(parseDateTime(rainTimeList.last));
    rank();
  }

  rank() {
    setState(() {
      ranked = data.entries.map((e) {
        double value;
        switch (interval) {
          case Intervals.now:
            value = e.value.now;
            break;
          case Intervals.tenMinutes:
            value = e.value.tenMinutes;
            break;
          case Intervals.oneHour:
            value = e.value.oneHour;
            break;
          case Intervals.threeHours:
            value = e.value.threeHours;
            break;
          case Intervals.sixHours:
            value = e.value.sixHours;
            break;
          case Intervals.twelveHours:
            value = e.value.twelveHours;
            break;
          case Intervals.twentyFourHours:
            value = e.value.twentyFourHours;
            break;
          case Intervals.twoDays:
            value = e.value.twoDays;
            break;
          case Intervals.threeDays:
            value = e.value.threeDays;
            break;
        }
        return (e.key, value);
      }).sorted((a, b) => (b.$2 - a.$2).sign.toInt());
    });
  }

  setInterval(Intervals i) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            "資料時間：$time",
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: kToolbarHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runAlignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("目前"),
                  selected: interval == Intervals.now,
                  onSelected: (value) => setInterval(Intervals.now),
                ),
                ChoiceChip(
                  label: Text("10 分鐘"),
                  selected: interval == Intervals.tenMinutes,
                  onSelected: (value) => setInterval(Intervals.tenMinutes),
                ),
                ChoiceChip(
                  label: Text("1 小時"),
                  selected: interval == Intervals.oneHour,
                  onSelected: (value) => setInterval(Intervals.oneHour),
                ),
                ChoiceChip(
                  label: Text("3 小時"),
                  selected: interval == Intervals.threeHours,
                  onSelected: (value) => setInterval(Intervals.threeHours),
                ),
                ChoiceChip(
                  label: Text("6 小時"),
                  selected: interval == Intervals.sixHours,
                  onSelected: (value) => setInterval(Intervals.sixHours),
                ),
                ChoiceChip(
                  label: Text("12 小時"),
                  selected: interval == Intervals.twelveHours,
                  onSelected: (value) => setInterval(Intervals.twelveHours),
                ),
                ChoiceChip(
                  label: Text("24 小時"),
                  selected: interval == Intervals.twentyFourHours,
                  onSelected: (value) => setInterval(Intervals.twentyFourHours),
                ),
                ChoiceChip(
                  label: Text("2 天"),
                  selected: interval == Intervals.twoDays,
                  onSelected: (value) => setInterval(Intervals.twoDays),
                ),
                ChoiceChip(
                  label: Text("3 天"),
                  selected: interval == Intervals.threeDays,
                  onSelected: (value) => setInterval(Intervals.threeDays),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 4, bottom: context.padding.bottom),
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

                final backgroundColor = index == 0
                    ? context.theme.extendedColors.amberContainer
                    : index == 1
                        ? context.theme.extendedColors.greyContainer
                        : index == 2
                            ? context.theme.extendedColors.brownContainer
                            : index < 10
                                ? context.colors.surfaceContainerHigh
                                : context.colors.surfaceContainer;

                final foregroundColor = index == 0
                    ? context.theme.extendedColors.onAmberContainer
                    : index == 1
                        ? context.colors.onSurface
                        : index == 2
                            ? context.theme.extendedColors.onBrownContainer
                            : index < 10
                                ? context.colors.onSurface
                                : context.colors.onSurfaceVariant;

                final iconColor = index == 0
                    ? context.theme.extendedColors.amber
                    : index == 1
                        ? context.theme.extendedColors.grey
                        : context.theme.extendedColors.brown;

                final double fontSize = index == 0
                    ? 20
                    : index < 3
                        ? 18
                        : 16;

                final double iconSize = index == 0
                    ? 32
                    : index == 1
                        ? 28
                        : 24;

                final leading = index < 3
                    ? Icon(
                        index == 0 ? Symbols.trophy_rounded : Symbols.workspace_premium_rounded,
                        color: iconColor,
                        size: iconSize,
                        fill: 1,
                      )
                    : Text(
                        "$rank",
                        style: TextStyle(color: foregroundColor, fontSize: fontSize),
                      );

                final percentage = item.$2 / ranked[0].$2;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Center(child: leading),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: backgroundColor,
                            gradient: LinearGradient(colors: [
                              backgroundColor,
                              backgroundColor,
                              backgroundColor.withOpacity(0.4),
                              backgroundColor.withOpacity(0.4),
                            ], stops: [
                              0,
                              percentage,
                              percentage,
                              1
                            ]),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      item.$1.name,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: index == 0
                                            ? FontWeight.bold
                                            : index < 3
                                                ? FontWeight.w500
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.$1.county,
                                      style: TextStyle(
                                        fontSize: fontSize / 1.25,
                                        color: foregroundColor.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      item.$1.town,
                                      style: TextStyle(
                                        fontSize: fontSize / 1.25,
                                        color: foregroundColor.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${item.$2} mm",
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: index == 0
                                      ? FontWeight.bold
                                      : index < 3
                                          ? FontWeight.w500
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
