import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/widget/list/timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/api/exptech.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<History> historyList = [];
  List<String> radar_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  Future<void> refreshHistoryList() async {
    final data = await ExpTech().getHistory();
    setState(() => historyList = data);
  }

  @override
  void initState() {
    super.initState();
    refreshHistoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.home),
      ),
      body: RefreshIndicator(
        onRefresh: refreshHistoryList,
        child: ListView(
          children: [
            Builder(
              builder: (context) {
                if (historyList.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Widget> children = [];

                for (var i = 0, n = historyList.length; i < n; i++) {
                  final current = historyList[i];
                  var showDate = false;

                  if (i != 0) {
                    final prev = historyList[i - 1];
                    if (current.time.send.day != prev.time.send.day) {
                      showDate = true;
                    }
                  } else {
                    showDate = true;
                  }
                  final item = TimeLineTile(
                    time: current.time.send,
                    icon: const Icon(Symbols.thunderstorm_rounded),
                    height: 100,
                    first: i == 0,
                    showDate: showDate,
                    color: context.theme.extendedColors.blueContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.text.content["all"]!.subtitle, style: context.theme.textTheme.titleMedium),
                        Text(current.text.description["all"]!),
                      ],
                    ),
                    onTap: () {},
                  );

                  children.add(item);
                }

                return Column(
                  children: children,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
