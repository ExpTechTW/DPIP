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
  final _scrollController = ScrollController();
  List<PartialEarthquakeReport> reportList = [];
  DateTime? lastFetchTime;
  int page = 1;
  bool isLoading = false;
  int _currentPage = 1;
  int _loadedPage = 0;

  Future<void> refreshReportList() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!).inMinutes < 1) {
      return;
    }

    var newList = await ExpTech().getReportList(limit: 500);
    addToList(newList);
  }

  void _loadMore() {
    if (isLoading) return;
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        _currentPage++;
        _fetchNextPage();
      });
    }
  }

  Future<void> _fetchNextPage() async {
    if (isLoading) return;
    if (_currentPage <= _loadedPage) {
      setState(() {
        _currentPage = _loadedPage;
      });
      return;
    }

    setState(() => isLoading = true);

    var newList = await ExpTech().getReportList(limit: 500, page: _currentPage);
    addToList(newList);

    setState(() {
      _loadedPage = _currentPage;
      isLoading = false;
    });
  }

  void addToList(List<PartialEarthquakeReport> list) {
    final oldIdList = reportList.map((v) => v.id);

    list.removeWhere(
      (r) => oldIdList.contains(r.id),
    );

    list = reportList + list;

    list.sort((a, b) => b.time.difference(a.time).inMilliseconds);

    setState(() {
      reportList = list;
      lastFetchTime = DateTime.now();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    _fetchNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.report),
        bottom: PreferredSize(
          preferredSize: const Size(double.maxFinite, 4),
          child: Visibility(
            visible: isLoading,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(4),
              backgroundColor: context.colors.secondaryContainer,
            ),
          ),
        ),
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
              controller: _scrollController,
              itemCount: reportList.length,
              itemBuilder: (context, index) {
                var showDate = false;
                final current = reportList[index];

                if (index != 0) {
                  final prev = reportList[index - 1];
                  if (current.time.day != prev.time.day) {
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
