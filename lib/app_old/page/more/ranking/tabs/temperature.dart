import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/parser.dart';

enum MergeType { none, county, town }

class RankingTemperatureTab extends StatefulWidget {
  const RankingTemperatureTab({super.key});

  @override
  State<RankingTemperatureTab> createState() => _RankingTemperatureTabState();
}

class _RankingTemperatureTabState extends State<RankingTemperatureTab> {
  MergeType merge = MergeType.none;
  bool reversed = false;
  String time = "";
  List<WeatherStation> data = [];
  List<WeatherStation> ranked = [];

  Future<void> refresh() async {
    final weatherList = await ExpTech().getWeatherList();
    final latestWeatherData = await ExpTech().getWeather(weatherList.last);

    if (!mounted) return;

    data = latestWeatherData.where((station) => station.data.air.temperature != -99).toList();
    time = DateFormat(context.i18n.datetime_format).format(parseDateTime(weatherList.last));
    rank();
  }

  rank() {
    final temp =
        (merge != MergeType.none)
            ? groupBy(
              data,
              (e) => merge == MergeType.town ? (e.station.county, e.station.town) : e.station.county,
            ).values.map(
              (v) => v.reduce(
                (acc, e) =>
                    (reversed
                            ? e.data.air.temperature < acc.data.air.temperature
                            : e.data.air.temperature > acc.data.air.temperature)
                        ? e
                        : acc,
              ),
            )
            : data;

    final sorted = temp.sorted((a, b) => (b.data.air.temperature - a.data.air.temperature).sign.toInt()).toList();
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
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(context.i18n.according)),
                  ChoiceChip(
                    label: Text(context.i18n.highest),
                    selected: !reversed,
                    onSelected: (value) => setReversed(false),
                  ),
                  ChoiceChip(
                    label: Text(context.i18n.lowest),
                    selected: reversed,
                    onSelected: (value) => setReversed(true),
                  ),
                  const SizedBox(height: kToolbarHeight - 16, child: VerticalDivider()),
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
                        : Text("$rank", style: TextStyle(color: foregroundColor, fontSize: fontSize));

                final percentage =
                    reversed
                        ? (ranked.first.data.air.temperature - item.data.air.temperature) /
                            (ranked.first.data.air.temperature - ranked.last.data.air.temperature)
                        : (item.data.air.temperature - ranked.last.data.air.temperature) /
                            (ranked.first.data.air.temperature - ranked.last.data.air.temperature);

                final location =
                    merge != MergeType.none
                        ? [
                          Text(
                            merge == MergeType.town
                                ? "${item.station.county}${item.station.town}"
                                : item.station.county,
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
                        ]
                        : [
                          Text(
                            item.station.name,
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
                            "${item.station.county}${item.station.town}",
                            style: TextStyle(fontSize: fontSize / 1.25, color: foregroundColor.withOpacity(0.8)),
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
                    "${item.data.air.temperature.toStringAsFixed(1)}℃",
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
                                backgroundColor.withOpacity(0.4),
                                backgroundColor.withOpacity(0.4),
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
