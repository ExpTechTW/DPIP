import 'dart:io';

import 'package:dpip/global.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/widget/earthquake_report_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReportList extends StatefulWidget {
  const ReportList({super.key});

  @override
  State<StatefulWidget> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> with AutomaticKeepAliveClientMixin<ReportList> {
  List<PartialEarthquakeReport> reports = [];

  Future<void> refreshReports() async {
    Global.api.getReportList(limit: 50).then((value) {
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
  get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    refreshReports();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("地震報告"),
        ),
        child: reports.isNotEmpty
            /*
            RefreshIndicator.adaptive(
                onRefresh: refreshReports,
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    return EarthquakeReportListTile(report: reports[index]);
                  },
                ),
              )*/
            ? ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  return EarthquakeReportListTile(report: reports[index]);
                },
              )
            : const Center(child: CupertinoActivityIndicator()),
      );
    } else {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            const SliverAppBar(
              title: Text("地震報告"),
              centerTitle: true,
              floating: true,
              snap: true,
            )
          ];
        },
        body: reports.isNotEmpty
            ? RefreshIndicator(
                onRefresh: refreshReports,
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    return EarthquakeReportListTile(report: reports[index]);
                  },
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }
  }
}
