import 'package:dpip/model/history.dart';
import 'package:flutter/material.dart';
import 'package:dpip/util/extension/build_context.dart';

import '../../../api/exptech.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<History> historyList = [];
  final _scrollController = ScrollController();

  Future<void> refreshHistoryList() async {
    historyList = await ExpTech().getHistory();
    setState(() {});
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                // color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '台北市 中正區',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: context.colors.secondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '27.0°C',
                        style: TextStyle(
                          color: context.colors.secondary,
                          fontSize: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '降水量: 0.56 mm\n濕度: 89.0 %\n體感: 31.4°C',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '更新時間: 07/26 00:00',
                    style: TextStyle(
                      color: context.colors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                if (historyList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await refreshHistoryList();
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    controller: _scrollController,
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      var showDate = false;
                      final current = historyList[index];

                      // if (index != 0) {
                      //   final prev = historyList[index - 1];
                      //   if (current.time.day != prev.time.day) {
                      //     showDate = true;
                      //   }
                      // } else {
                      //   showDate = true;
                      // }

                      return SizedBox(
                        height: 15,
                        child: Text(current.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(int index) {
    switch (index) {
      case 0:
      case 3:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 4:
      default:
        return Colors.red;
    }
  }
}
