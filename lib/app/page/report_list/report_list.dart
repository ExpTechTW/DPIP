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

  Future<List<PartialEarthquakeReport>> fetchReportList() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!).inMinutes < 1) {
      return reportList;
    }

    var data = await ExpTech().getReportList();

    data = (data + reportList).toSet().toList();
    data.sort((a, b) => b.time - a.time);

    setState(() {
      reportList = data;
    });

    return reportList;
  }

  @override
  void initState() {
    super.initState();
    fetchReportList();
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

          return ListView.builder(
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

              return ReportListItem(report: current, showDate: showDate);
            },
          );
        },
      ),
    );
  }
}
