import 'package:dpip/core/utils.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/view/report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportList extends StatefulWidget {
  const ReportList({super.key});

  @override
  State<StatefulWidget> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> {
  List<PartialEarthquakeReport> reports = [];

  Future<void> refreshReports() async {
    Global.api.getReportList().then((value) {
      setState(() {
        reports = value;
      });
    }).catchError((error) {
      context.scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("請求資料時發生錯誤 ${error.toString()}"),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    refreshReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("地震報告"),
        centerTitle: true,
      ),
      body: reports.isNotEmpty
          ? RefreshIndicator(
              onRefresh: refreshReports,
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(reports[index].getLocation()),
                  subtitle: Text(
                    DateFormat("yyyy/MM/dd HH:mm:ss").format(
                      DateTime.fromMillisecondsSinceEpoch(
                        reports[index].time,
                      ),
                    ),
                  ),
                  trailing: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: context.colors.intensity(reports[index].intensity),
                    ),
                    child: Center(
                      child: Text(
                        intensityToNumberString(reports[index].intensity),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.colors
                              .onIntensity(reports[index].intensity),
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportPage(report: reports[index]),
                      ),
                    );
                  },
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
