import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/model/history.dart';
import 'package:flutter/material.dart';

class HistoryCountryTab extends StatefulWidget {
  const HistoryCountryTab({super.key});

  @override
  State<HistoryCountryTab> createState() => _HistoryCountryTabState();
}

class _HistoryCountryTabState extends State<HistoryCountryTab> {
  final list = GlobalKey<RefreshIndicatorState>();
  bool isLoading = true;
  List<History> historyList = [];

  Future<void> refreshHistoryList() async {
    setState(() => isLoading = true);
    try {
      final data = await ExpTech().getHistory();
      setState(() {
        historyList = data.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        list.currentState?.show();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: list,
      onRefresh: refreshHistoryList,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final history = historyList[index];
          return HistoryTimelineItem(
            history: history,
            first: index == 0,
            last: index == historyList.length - 1,
          );
        },
      ),
    );
  }
}
