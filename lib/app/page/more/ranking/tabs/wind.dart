import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/weather/weather.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/util/parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

enum MergeType {
  none,
  county,
  town,
}

class RankingWindTab extends StatefulWidget {
  const RankingWindTab({super.key});

  @override
  State<RankingWindTab> createState() => _RankingWindTabState();
}

class _RankingWindTabState extends State<RankingWindTab> {
  MergeType merge = MergeType.none;
  bool reversed = false;
  String time = "";
  List<WeatherStation> data = [];
  List<WeatherStation> ranked = [];

  Future<void> refresh() async {
    final weatherList = await ExpTech().getWeatherList();
    final latestWeatherData = await ExpTech().getWeather(weatherList.last);

    if (!mounted) return;

    data = latestWeatherData.where((station) => station.data.wind.speed != -99).toList();
    time = DateFormat(context.i18n.datetime_format).format(parseDateTime(weatherList.last));
    rank();
  }

  rank() {
    final temp = (merge != MergeType.none)
        ? groupBy(data, (e) => merge == MergeType.town ? (e.station.county, e.station.town) : e.station.county)
            .values
            .map((v) => v.reduce((acc, e) =>
                (reversed ? e.data.wind.speed < acc.data.wind.speed : e.data.wind.speed > acc.data.wind.speed)
                    ? e
                    : acc))
        : data;

    final sorted = temp
        .where((e) => e.data.wind.speed > 0)
        .sorted((a, b) => (b.data.wind.speed - a.data.wind.speed).sign.toInt())
        .toList();

    setState(() {
      ranked = reversed ? sorted.reversed.toList() : sorted;
    });
  }

  setMerge(MergeType state) {
    if (state == merge) {
      merge = MergeType.none;
    } else {
      merge = state;
    }
    rank();
  }

  setReversed(bool state) {
    reversed = state;
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(context.i18n.according),
                  ),
                  ChoiceChip(
                    label: Text(context.i18n.ranking_descending),
                    selected: !reversed,
                    onSelected: (value) => setReversed(false),
                  ),
                  ChoiceChip(
                    label: Text(context.i18n.ranking_ascending),
                    selected: reversed,
                    onSelected: (value) => setReversed(true),
                  ),
                  const SizedBox(
                    height: kToolbarHeight - 16,
                    child: VerticalDivider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(context.i18n.ranking_merge_into),
                  ),
                  ChoiceChip(
                    label: Text(context.i18n.location_town),
                    selected: merge == MergeType.town,
                    onSelected: (value) => setMerge(MergeType.town),
                  ),
                  ChoiceChip(
                    label: Text(context.i18n.location_city),
                    selected: merge == MergeType.county,
                    onSelected: (value) => setMerge(MergeType.county),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.i18n.ranking_time(time.toString(), ranked.length.toString()),
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

                final minWind = reversed ? ranked.first.data.wind.speed : ranked.last.data.wind.speed;
                final maxWind = reversed ? ranked.last.data.wind.speed : ranked.first.data.wind.speed;
                final percentage = (item.data.wind.speed - minWind) / (maxWind - minWind);

                final location = merge != MergeType.none
                    ? [
                        Text(
                          merge == MergeType.town ? "${item.station.county}${item.station.town}" : item.station.county,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: index == 0
                                ? FontWeight.bold
                                : index < 3
                                    ? FontWeight.w500
                                    : null,
                          ),
                        ),
                      ]
                    : [
                        Text(
                          item.station.name,
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
                          "${item.station.county}${item.station.town}",
                          style: TextStyle(
                            fontSize: fontSize / 1.25,
                            color: foregroundColor.withOpacity(0.8),
                          ),
                        ),
                      ];

                final content = [
                  Expanded(
                    child: index < 3
                        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: location)
                        : Row(children: location),
                  ),
                  Text(
                    "${item.data.wind.speed.toStringAsFixed(1)} m/s",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: index == 0
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
                          child: Row(children: content),
                        ),
                      )
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
