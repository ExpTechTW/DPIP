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
  bool showRetryButton = false;
  bool refreshing = false;

  Future<void> refreshReports() async {
    setState(() {
      refreshing = true;
    });

    Global.api.getReportList(limit: 50).then((value) {
      setState(() {
        reports = value;
        refreshing = false;
      });
    }).catchError((error) {
      if (Platform.isAndroid) {
        setState(() {
          showRetryButton = true;
          refreshing = false;
        });
      } else {
        context.scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("請求資料時發生錯誤 ${error.toString()}"),
          ),
        );
      }
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
        navigationBar: CupertinoNavigationBar(
          middle: const Text("地震報告"),
          trailing: Visibility(
            visible: reports.isNotEmpty,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: refreshing ? const CupertinoActivityIndicator() : const Icon(CupertinoIcons.refresh),
              onPressed: () {
                if (refreshing) return;
                refreshReports();
              },
            ),
          ),
        ),
        child: SafeArea(
          child: showRetryButton
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("無法取的地震報告"),
                      CupertinoButton(
                        child: const Text("再試一次"),
                        onPressed: () {
                          refreshReports();

                          setState(() {
                            showRetryButton = false;
                          });
                        },
                      )
                    ],
                  ),
                )
              : reports.isNotEmpty
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
        ),
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
        body: SafeArea(
          child: reports.isEmpty && showRetryButton
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "無法取得地震報告",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        child: const Text("再試一次"),
                        onPressed: () {
                          refreshReports();

                          setState(() {
                            showRetryButton = false;
                          });
                        },
                      )
                    ],
                  ),
                )
              : reports.isNotEmpty
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
        ),
      );
    }
  }
}
