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
  bool isLoading = false;
  bool isLoadingEnd = false;
  int _currentPage = 1;
  int _loadedPage = 0;

  RangeValues _intensityRange = const RangeValues(0, 8);
  RangeValues _magnitudeRange = const RangeValues(0, 10);
  RangeValues _depthRange = const RangeValues(0, 700);
  final List<String> _intensityLevels = ['1級', '2級', '3級', '4級', '5弱', '5強', '6弱', '6強', '7級'];

  Future<void> refreshReportList() async {
    if (lastFetchTime != null && DateTime.now().difference(lastFetchTime!).inMinutes < 1) {
      return;
    }
    if (isLoadingEnd) return;

    setState(() {
      isLoading = true;
      _currentPage = 1;
      _loadedPage = 0;
      reportList.clear();
    });

    await _fetchNextPage();
  }

  void _loadMore() {
    if (isLoading) return;
    if (isLoadingEnd) return;
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

    var newList = await ExpTech().getReportList(
      limit: 500,
      page: _currentPage,
      minIntensity: (_intensityRange.start + 1).round(),
      maxIntensity: (_intensityRange.end + 1).round(),
      minMagnitude: _magnitudeRange.start.round(),
      maxMagnitude: _magnitudeRange.end.round(),
      minDepth: _depthRange.start.round(),
      maxDepth: _depthRange.end.round(),
    );
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

  String _getFilterSummary() {
    List<String> summaries = [];

    if (_intensityRange.start > 0 || _intensityRange.end < 8) {
      summaries.add(
          '${context.i18n.max_earthquake_intensity}: ${_intensityLevels[_intensityRange.start.round()]}-${_intensityLevels[_intensityRange.end.round()]}');
    }
    if (_magnitudeRange.start > 0 || (_magnitudeRange.end > 0 && _magnitudeRange.end < 10)) {
      summaries.add('${context.i18n.scale}: ${_magnitudeRange.start.round()}-${_magnitudeRange.end.round()}');
    }
    if (_depthRange.start > 0 || (_depthRange.end > 0 && _depthRange.end < 700)) {
      summaries.add('${context.i18n.depth}: ${_depthRange.start.round()}-${_depthRange.end.round()}km');
    }

    return summaries.isEmpty ? context.i18n.report_all : summaries.join(', ');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.i18n.report_filter),
            Text(
              _getFilterSummary(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: isLoading,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(4),
              backgroundColor: context.colors.secondaryContainer,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshReportList,
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: reportList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == reportList.length) {
                        if (!isLoading) {
                          isLoadingEnd = true;
                        } else if (isLoading) {
                          isLoadingEnd = false;
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: isLoading ? const CircularProgressIndicator() : const Text('到底了'),
                          ),
                        );
                      }

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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(context.i18n.report_filter),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.i18n.max_earthquake_intensity),
                    RangeSlider(
                      values: _intensityRange,
                      min: 0,
                      max: 8,
                      divisions: 8,
                      labels: RangeLabels(
                        _intensityLevels[_intensityRange.start.round()],
                        _intensityLevels[_intensityRange.end.round()],
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _intensityRange = RangeValues(
                            values.start.roundToDouble(),
                            values.end.roundToDouble(),
                          );
                        });
                      },
                    ),
                    Text(context.i18n.scale),
                    RangeSlider(
                      values: _magnitudeRange,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      labels: RangeLabels(
                        _magnitudeRange.start.round().toString(),
                        _magnitudeRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _magnitudeRange = RangeValues(
                            values.start.roundToDouble(),
                            values.end.roundToDouble(),
                          );
                        });
                      },
                    ),
                    Text(context.i18n.depth),
                    RangeSlider(
                      values: _depthRange,
                      min: 0,
                      max: 700,
                      divisions: 70,
                      labels: RangeLabels(
                        "${_depthRange.start.round()}km",
                        "${_depthRange.end.round()}km",
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _depthRange = RangeValues(
                            values.start.roundToDouble(),
                            values.end.roundToDouble(),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(context.i18n.report_filter_reset),
                  onPressed: () {
                    setState(() {
                      _intensityRange = const RangeValues(0, 8);
                      _magnitudeRange = const RangeValues(0, 10);
                      _depthRange = const RangeValues(0, 700);
                    });
                  },
                ),
                TextButton(
                  child: Text(context.i18n.report_filter_apply),
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {
                      _currentPage = 1;
                      _loadedPage = 0;
                      reportList.clear();
                      _fetchNextPage();
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
