import 'dart:io';

import 'package:dpip/global.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/widget/earthquake_report_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReportList extends StatefulWidget {
  const ReportList({super.key});

  @override
  State<StatefulWidget> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> with AutomaticKeepAliveClientMixin<ReportList> {
  final ScrollController _controller = ScrollController();
  List<PartialEarthquakeReport> reports = [];
  bool showRetryButton = false;
  bool refreshing = false;
  bool _isScrollToTopVisible = false;

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

  void _scrollToTop() {
    _controller.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Easing.standard,
    );
  }

  @override
  get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    refreshReports();

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.minScrollExtent) {
        setState(() {
          _isScrollToTopVisible = false;
        });
      } else {
        setState(() {
          _isScrollToTopVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("地震報告"),
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
                  ? CustomScrollView(
                      controller: _controller,
                      slivers: [
                        CupertinoSliverRefreshControl(
                          onRefresh: refreshReports,
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return EarthquakeReportListTile(report: reports[index]);
                            },
                            childCount: reports.length,
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CupertinoActivityIndicator()),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("地震報告"),
          centerTitle: true,
        ),
        floatingActionButton: AnimatedScale(
          scale: _isScrollToTopVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.small(
            onPressed: _scrollToTop,
            child: const Icon(Symbols.vertical_align_top_rounded),
          ),
        ),
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
                        controller: _controller,
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
