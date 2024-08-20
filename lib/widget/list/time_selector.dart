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

class _TimeSelectorState extends State<TimeSelector> {
  late DateTime _selectedTime;
  late List<DateTime> _timeList;
  late ScrollController _scrollController;
  final double _itemWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _generateTimeList();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
