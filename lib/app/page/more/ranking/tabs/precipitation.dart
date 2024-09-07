import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dpip/app/page/more/ranking/widgets/ranking_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/weather/rain.dart';

class RankingPrecipitationTab extends StatefulWidget {
  const RankingPrecipitationTab({super.key});

  @override
  State<RankingPrecipitationTab> createState() => _RankingPrecipitationTabState();
}

class _RankingPrecipitationTabState extends State<RankingPrecipitationTab> {
  List<int> data = [];
  List<String> rainTimeList = [];
  List<RainData> rainDataList = [];

  Future refresh() async {
    rainTimeList = await ExpTech().getRainList();

    List<RainStation> rainData = await ExpTech().getRain(rainTimeList.last);

    // rainDataList = rainData
    //     .map((station) {
    //   double rainfall;
    //   switch (interval) {
    //     case "now":
    //       rainfall = station.data.now;
    //       break;
    //     case "10m":
    //       rainfall = station.data.tenMinutes;
    //       break;
    //     case "1h":
    //       rainfall = station.data.oneHour;
    //       break;
    //     case "3h":
    //       rainfall = station.data.threeHours;
    //       break;
    //     case "6h":
    //       rainfall = station.data.sixHours;
    //       break;
    //     case "12h":
    //       rainfall = station.data.twelveHours;
    //       break;
    //     case "24h":
    //       rainfall = station.data.twentyFourHours;
    //       break;
    //     case "2d":
    //       rainfall = station.data.twoDays;
    //       break;
    //     case "3d":
    //       rainfall = station.data.threeDays;
    //       break;
    //     default:
    //       rainfall = station.data.now;
    //   }
    //
    //   if (rainfall == -99) {
    //     return null;
    //   }
    //
    //   return RainData(
    //     id: station.id,
    //     latitude: station.station.lat,
    //     longitude: station.station.lng,
    //     rainfall: rainfall,
    //     stationName: station.station.name,
    //     county: station.station.county,
    //     town: station.station.town,
    //   );
    // })
    //     .whereType<RainData>()
    //     .toList();

    setState(() {
      data = List.generate(200, (index) => Random().nextInt((index + 1) * (index + 1))).sorted((a, b) => b - a);
    });
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
      child: RankingList(
        data: data,
        contentBuilder: (context, item, rank) {
          if (rank == 1) {
            return Row(
              children: [
                const Icon(Symbols.trophy_rounded),
                const SizedBox(width: 8),
                Text(
                  "$item",
                  style: TextStyle(fontSize: 20),
                ),
              ],
            );
          }

          return Row(
            children: [
              Text("$rank"),
              const SizedBox(width: 8),
              Text("$item"),
            ],
          );
        },
      ),
    );
  }
}
