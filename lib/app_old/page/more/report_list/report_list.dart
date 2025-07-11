import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/report/list_item.dart';
import 'package:flutter/material.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final scroll = GlobalKey<NestedScrollViewState>();
  List<PartialEarthquakeReport> reportList = [];
  DateTime? lastFetchTime;
  bool isLoading = false;
  bool isLoadingEnd = false;
  int _currentPage = 1;
  int _loadedPage = 0;

  RangeValues _intensityRange = const RangeValues(0, 8);
  RangeValues _magnitudeRange = const RangeValues(0, 10);
  RangeValues _depthRange = const RangeValues(0, 700);

  List<String> get _intensityLevels => List.generate(9, (i) {
    final count = i + 1;
    const map = {5: '5弱', 6: '5強', 7: '6弱', 8: '6強', 9: '7級'};
    return map[count] ?? '$count級';
  });

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
    if (scroll.currentState == null) return;

    if (scroll.currentState!.innerController.position.pixels ==
        scroll.currentState!.innerController.position.maxScrollExtent) {
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

    final newList = await ExpTech().getReportList(
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

    list.removeWhere((r) => oldIdList.contains(r.id));

    list = reportList + list;

    list.sort((a, b) => b.time.difference(a.time).inMilliseconds);

    setState(() {
      reportList = list;
      lastFetchTime = DateTime.now();
    });
  }

  String _getFilterSummary() {
    final List<String> summaries = [];

    if (_intensityRange.start > 0 || _intensityRange.end < 8) {
      summaries.add(
        '最大震度: ${_intensityLevels[_intensityRange.start.round()]}-${_intensityLevels[_intensityRange.end.round()]}',
      );
    }
    if (_magnitudeRange.start > 0 || (_magnitudeRange.end > 0 && _magnitudeRange.end < 10)) {
      summaries.add('規模: ${_magnitudeRange.start.round()}-${_magnitudeRange.end.round()}');
    }
    if (_depthRange.start > 0 || (_depthRange.end > 0 && _depthRange.end < 700)) {
      summaries.add('深度: ${_depthRange.start.round()}-${_depthRange.end.round()}km');
    }

    return summaries.isEmpty ? '全部' : summaries.join(', ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scroll.currentState?.innerController.addListener(_loadMore);
    });
    _fetchNextPage();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text('地震報告'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Wrap(
                  children: [
                    FilterChip(
                      label: Text(_getFilterSummary() == '全部' ? '篩選器' : _getFilterSummary()),
                      selected: _getFilterSummary() != '全部',
                      onSelected: (_) => _showFilterDialog(),
                    ),
                  ],
                ),
              ),
            ),
            shape: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
          ),
        ];
      },
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
                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: context.padding.bottom),
                    itemCount: reportList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == reportList.length) {
                        if (!isLoading) {
                          isLoadingEnd = true;
                        } else if (isLoading) {
                          isLoadingEnd = false;
                        }
                        return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: Text('到底了')));
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('篩選器'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('最大震度'),
                    RangeSlider(
                      values: _intensityRange,
                      max: 8,
                      divisions: 8,
                      labels: RangeLabels(
                        _intensityLevels[_intensityRange.start.round()],
                        _intensityLevels[_intensityRange.end.round()],
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _intensityRange = RangeValues(values.start.roundToDouble(), values.end.roundToDouble());
                        });
                      },
                    ),
                    const Text('規模'),
                    RangeSlider(
                      values: _magnitudeRange,
                      max: 10,
                      divisions: 10,
                      labels: RangeLabels(
                        _magnitudeRange.start.round().toString(),
                        _magnitudeRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _magnitudeRange = RangeValues(values.start.roundToDouble(), values.end.roundToDouble());
                        });
                      },
                    ),
                    const Text('深度'),
                    RangeSlider(
                      values: _depthRange,
                      max: 700,
                      divisions: 70,
                      labels: RangeLabels('${_depthRange.start.round()}km', '${_depthRange.end.round()}km'),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _depthRange = RangeValues(values.start.roundToDouble(), values.end.roundToDouble());
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('重置'),
                  onPressed: () {
                    setState(() {
                      _intensityRange = const RangeValues(0, 8);
                      _magnitudeRange = const RangeValues(0, 10);
                      _depthRange = const RangeValues(0, 700);
                    });
                  },
                ),
                TextButton(
                  child: const Text('套用'),
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
