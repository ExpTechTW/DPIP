import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dpip/app/page/more/ranking/widgets/ranking_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class RankingPrecipitationTab extends StatefulWidget {
  const RankingPrecipitationTab({super.key});

  @override
  State<RankingPrecipitationTab> createState() => _RankingPrecipitationTabState();
}

class _RankingPrecipitationTabState extends State<RankingPrecipitationTab> {
  List<int> data = [];

  Future refresh() async {
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
