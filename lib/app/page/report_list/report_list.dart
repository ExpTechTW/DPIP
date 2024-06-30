import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/report/list_item.dart';
import 'package:flutter/material.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  List<PartialEarthquakeReport> reportList = [];
  DateTime? lastFetchTime;

  Future<List<PartialEarthquakeReport>> refreshReportList() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!).inMinutes < 1) {
      return reportList;
    }

    final oldIdList = reportList.map((v) => v.id);

    var newList = await ExpTech().getReportList();

    newList.removeWhere(
      (r) => oldIdList.contains(r.id),
    );

    newList = reportList + newList;

    newList.sort((a, b) => b.time - a.time);

    setState(() {
      reportList = newList;
    });

    return reportList;
  }

  @override
  void initState() {
    super.initState();
    refreshReportList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.report),
      ),
      body: Builder(
        builder: (context) {
          if (reportList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await refreshReportList();
            },
            child: ListView.builder(
              itemCount: reportList.length,
              itemBuilder: (context, index) {
                var showDate = false;
                final current = reportList[index];

                if (index != 0) {
                  final prev = reportList[index - 1];
                  if (current.dateTime.day != prev.dateTime.day) {
                    showDate = true;
                  }
                } else {
                  showDate = true;
                }

                return ReportListItem(
                  report: current,
                  showDate: showDate,
                  first: index == 0,
                  refreshReportList: refreshReportList,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
