import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RainTimeSelector extends StatefulWidget {
  final Function(String, String) onSelectionChanged;
  final Function() onTimeExpanded;
  final List<String> timeList;

  const RainTimeSelector({
    super.key,
    required this.onSelectionChanged,
    required this.onTimeExpanded,
    required this.timeList,
  });

  @override
  State<RainTimeSelector> createState() => _RainTimeSelectorState();
}

class _RainTimeSelectorState extends State<RainTimeSelector> with SingleTickerProviderStateMixin {
  late String _selectedTimestamp;
  late String _selectedInterval;
  late ScrollController _timeScrollController;
  late ScrollController _intervalScrollController;
  final double _itemWidth = 80.0;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  int _select_index = 8;

  final List<String> _intervals = ['3d', '2d', '24h', '12h', '6h', '3h', '1h', '10m', 'now'];
  List<String> get _intervalTranslations => [
    '3 天',
    '3 天',
    '24 小時',
    '12 小時',
    '6 小時',
    '3 小時',
    '1 小時',
    '10 分鐘',
    '今日',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = widget.timeList.last;
    _selectedInterval = 'now'; // Default to now
    _timeScrollController = ScrollController();
    _intervalScrollController = ScrollController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
      _scrollToSelectedInterval();
    });
  }

  DateTime _convertTimestamp(String timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  }

  @override
  void dispose() {
    _timeScrollController.dispose();
    _intervalScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_timeScrollController.hasClients) return;
    final index = widget.timeList.indexOf(_selectedTimestamp);
    if (index != -1) {
      final totalWidth = _itemWidth * widget.timeList.length;
      final viewportWidth = _timeScrollController.position.viewportDimension;
      final maxScroll = _timeScrollController.position.maxScrollExtent;

      double targetScroll = (index * _itemWidth) - (viewportWidth / 2) + (_itemWidth / 2);

      targetScroll = targetScroll.clamp(0.0, maxScroll);

      if (totalWidth - targetScroll - viewportWidth < _itemWidth) {
        targetScroll = maxScroll;
      }

      _timeScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToSelectedInterval() {
    if (!_intervalScrollController.hasClients) return;
    final index = _intervals.indexOf(_selectedInterval);
    if (index != -1) {
      final totalWidth = _itemWidth * _intervals.length;
      final viewportWidth = _intervalScrollController.position.viewportDimension;
      final maxScroll = _intervalScrollController.position.maxScrollExtent;

      double targetScroll = (index * _itemWidth) - (viewportWidth / 2) + (_itemWidth / 2);

      targetScroll = targetScroll.clamp(0.0, maxScroll);

      if (totalWidth - targetScroll - viewportWidth < _itemWidth) {
        targetScroll = maxScroll;
      }

      _intervalScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        widget.onTimeExpanded();
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 64,
      child: Card(
        elevation: 4,
        surfaceTintColor: context.colors.surfaceTint,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ListView.builder(
            controller: _timeScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.timeList.length,
            itemBuilder: (context, index) {
              final timestamp = widget.timeList[index];
              final time = _convertTimestamp(timestamp);
              final isSelected = timestamp == _selectedTimestamp;
              return SizedBox(
                width: _itemWidth,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTimestamp = timestamp;
                    });
                    widget.onSelectionChanged(_selectedTimestamp, _selectedInterval);
                    _scrollToSelected();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.secondary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(time),
                          style: TextStyle(
                            color: isSelected ? context.colors.onSecondary : context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('MM/dd').format(time),
                          style: TextStyle(
                            color:
                                isSelected
                                    ? context.colors.onSecondary
                                    : context.colors.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return SizedBox(
      height: 58,
      child: Card(
        elevation: 4,
        surfaceTintColor: context.colors.surfaceTint,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ListView.builder(
            controller: _intervalScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _intervals.length,
            itemBuilder: (context, index) {
              final interval = _intervals[index];
              final translation = _intervalTranslations[index];
              final isSelected = interval == _selectedInterval;
              return SizedBox(
                width: _itemWidth,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInterval = interval;
                    });
                    _select_index = index;
                    widget.onSelectionChanged(_selectedTimestamp, _selectedInterval);
                    _scrollToSelectedInterval();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.secondary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translation,
                      style: TextStyle(
                        color: isSelected ? context.colors.onSecondary : context.colors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonalIcon(
            onPressed: _toggleExpanded,
            label: Text(
              "${DateFormat("yyyy/MM/dd HH:mm").format(_convertTimestamp(_selectedTimestamp))} (${_intervalTranslations[_select_index]})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icon(_isExpanded ? Icons.expand_more : Icons.expand_less),
            iconAlignment: IconAlignment.end,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(context.colors.surface),
              foregroundColor: WidgetStatePropertyAll(context.colors.onSurface),
              surfaceTintColor: WidgetStatePropertyAll(context.colors.surfaceTint),
              padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(16, 0, 12, 0)),
              elevation: const WidgetStatePropertyAll(4),
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _expandAnimation,
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(children: [_buildTimeSelector(), const SizedBox(height: 8), _buildIntervalSelector()]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
