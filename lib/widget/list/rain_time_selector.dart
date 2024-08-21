import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSelector extends StatefulWidget {
  final Function(String, String) onSelectionChanged;
  final List<String> timeList;

  const TimeSelector({
    Key? key,
    required this.onSelectionChanged,
    required this.timeList,
  }) : super(key: key);

  @override
  _TimeSelectorState createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> with SingleTickerProviderStateMixin {
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
  final List<String> _intervalTranslations = ['3天', '2天', '24小時', '12小時', '6小時', '3小時', '1小時', '10分鐘', '現在'];

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = widget.timeList.last;
    _selectedInterval = 'now'; // Default to now
    _timeScrollController = ScrollController();
    _intervalScrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
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
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 80,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MM/dd').format(time),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
    );
  }

  Widget _buildIntervalSelector() {
    return SizedBox(
      height: 80,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    translation,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onSurface,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${DateFormat('yyyy/MM/dd HH:mm').format(_convertTimestamp(_selectedTimestamp))} (${_intervalTranslations[_select_index]})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            children: [
              _buildTimeSelector(),
              _buildIntervalSelector(),
            ],
          ),
        ),
      ],
    );
  }
}
