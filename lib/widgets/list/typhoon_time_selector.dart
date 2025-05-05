import "package:dpip/utils/extensions/build_context.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

class TyphoonTimeSelector extends StatefulWidget {
  final Function(String, int) onSelectionChanged;
  final Function() onTimeExpanded;
  final List<String> timeList;
  final List<String> typhoonList;
  final List<int> typhoonIdList;
  final int selectedTyphoonId;

  const TyphoonTimeSelector({
    super.key,
    required this.onSelectionChanged,
    required this.onTimeExpanded,
    required this.timeList,
    required this.typhoonList,
    required this.selectedTyphoonId,
    required this.typhoonIdList,
  });

  @override
  State<TyphoonTimeSelector> createState() => _TyphoonTimeSelectorState();
}

class _TyphoonTimeSelectorState extends State<TyphoonTimeSelector> with SingleTickerProviderStateMixin {
  late String _selectedTimestamp;
  late int _selectedTyphoonId;
  late ScrollController _timeScrollController;
  late ScrollController _typhoonScrollController;
  final double _itemWidth = 80.0;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = widget.timeList.last;
    _selectedTyphoonId = widget.selectedTyphoonId;
    _timeScrollController = ScrollController();
    _typhoonScrollController = ScrollController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
      _scrollToSelectedTyphoon();
    });
  }

  DateTime _convertTimestamp(String timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  }

  @override
  void dispose() {
    _timeScrollController.dispose();
    _typhoonScrollController.dispose();
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

  void _scrollToSelectedTyphoon() {
    if (!_typhoonScrollController.hasClients) return;
    final index = widget.typhoonIdList.indexOf(_selectedTyphoonId);
    if (index != -1) {
      final totalWidth = _itemWidth * widget.typhoonList.length;
      final viewportWidth = _typhoonScrollController.position.viewportDimension;
      final maxScroll = _typhoonScrollController.position.maxScrollExtent;

      double targetScroll = (index * _itemWidth) - (viewportWidth / 2) + (_itemWidth / 2);

      targetScroll = targetScroll.clamp(0.0, maxScroll);

      if (totalWidth - targetScroll - viewportWidth < _itemWidth) {
        targetScroll = maxScroll;
      }

      _typhoonScrollController.animateTo(
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
                  widget.onSelectionChanged(_selectedTimestamp, _selectedTyphoonId);
                  _scrollToSelected();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat("HH:mm").format(time),
                        style: TextStyle(
                          color: isSelected ? context.colors.onSecondary : context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat("MM/dd").format(time),
                        style: TextStyle(
                          color: isSelected ? context.colors.onSecondary : context.colors.onSurface.withOpacity(0.7),
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

  Widget _buildTyphoonSelector() {
    return SizedBox(
      height: 80,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
          controller: _typhoonScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.typhoonList.length,
          itemBuilder: (context, index) {
            final typhoonId = widget.typhoonIdList[index];
            final isSelected = typhoonId == _selectedTyphoonId;
            return SizedBox(
              width: _itemWidth,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTyphoonId = typhoonId;
                  });
                  widget.onSelectionChanged(_selectedTimestamp, _selectedTyphoonId);
                  _scrollToSelectedTyphoon();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.secondary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.typhoonList[index],
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
    );
  }

  String get _selectedTyphoonName {
    final int index = widget.typhoonIdList.indexOf(_selectedTyphoonId);
    if (index != -1 && index < widget.typhoonList.length) {
      return widget.typhoonList[index];
    }
    return "未知";
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
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${DateFormat("yyyy/MM/dd HH:mm").format(_convertTimestamp(_selectedTimestamp))} ($_selectedTyphoonName)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.onSurface),
                ),
                const SizedBox(width: 4),
                Icon(_isExpanded ? Icons.expand_more : Icons.expand_less, color: context.colors.onSurface),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(children: [_buildTimeSelector(), _buildTyphoonSelector()]),
        ),
      ],
    );
  }
}
