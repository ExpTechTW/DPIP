import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSelector extends StatefulWidget {
  final Function(DateTime) onTimeSelected;
  final DateTime initialTime;
  final Duration interval;

  const TimeSelector({
    Key? key,
    required this.onTimeSelected,
    required this.initialTime,
    this.interval = const Duration(minutes: 10),
  }) : super(key: key);

  @override
  _TimeSelectorState createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> with SingleTickerProviderStateMixin {
  late DateTime _selectedTime;
  late List<DateTime> _timeList;
  late ScrollController _scrollController;
  final double _itemWidth = 80.0;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _generateTimeList();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _generateTimeList() {
    final now = DateTime.now();
    _timeList = List.generate(24 * 6, (index) {
      return now.subtract(Duration(minutes: (24 * 60) - (index * 10)));
    });
  }

  void _scrollToSelected() {
    final index = _timeList.indexWhere((time) => time.isAtSameMomentAs(_selectedTime));
    if (index != -1) {
      _scrollController.animateTo(
        index * _itemWidth,
        duration: Duration(milliseconds: 300),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            margin: EdgeInsets.only(bottom: 8, left: 16, right: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(_selectedTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 4),
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
          child: Container(
            height: 80,
            child: Card(
              margin: EdgeInsets.all(8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _timeList.length,
                itemBuilder: (context, index) {
                  final time = _timeList[index];
                  final isSelected = time.isAtSameMomentAs(_selectedTime);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                      widget.onTimeSelected(_selectedTime);
                      _scrollToSelected();
                    },
                    child: Container(
                      width: _itemWidth,
                      alignment: Alignment.center,
                      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                          SizedBox(height: 4),
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
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
