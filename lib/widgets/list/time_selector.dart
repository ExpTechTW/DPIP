import "package:dpip/utils/extensions/build_context.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

class TimeSelector extends StatefulWidget {
  final Function(String) onTimeSelected;
  final Function() onTimeExpanded;
  final List<String> timeList;

  const TimeSelector({super.key, required this.onTimeSelected, required this.onTimeExpanded, required this.timeList});

  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> with SingleTickerProviderStateMixin {
  late String _selectedTimestamp;
  late ScrollController _scrollController;
  final double _itemWidth = 80.0;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = widget.timeList.last;
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  DateTime _convertTimestamp(String timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final index = widget.timeList.indexOf(_selectedTimestamp);
    if (index != -1) {
      final selectedItemOffset = index * _itemWidth;
      final screenWidth = MediaQuery.of(context).size.width;
      final scrollOffset = selectedItemOffset - (screenWidth / 2) + (_itemWidth / 2);

      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: _toggleExpanded,
          label: Text(
            DateFormat("yyyy/MM/dd HH:mm").format(_convertTimestamp(_selectedTimestamp)),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: Icon(_isExpanded ? Icons.expand_more : Icons.expand_less),
          iconAlignment: IconAlignment.end,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(context.colors.surface),
            foregroundColor: WidgetStatePropertyAll(context.colors.onSurface),
            surfaceTintColor: WidgetStatePropertyAll(context.colors.surfaceTint),
            padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(16, 0, 12, 0)),
            elevation: const WidgetStatePropertyAll(2),
          ),
        ),
        FadeTransition(
          opacity: _expandAnimation,
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            child: SizedBox(
              height: 76,
              child: Card(
                margin: const EdgeInsets.all(8),
                elevation: 2,
                surfaceTintColor: context.colors.surfaceTint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ListView.builder(
                    controller: _scrollController,
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
                            widget.onTimeSelected(_selectedTimestamp);
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
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: isSelected ? context.colors.onSecondary : context.colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  child: Text(DateFormat("HH:mm").format(time)),
                                ),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? context.colors.onSecondary
                                            : context.colors.onSurface.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  child: Text(DateFormat("MM/dd").format(time)),
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
            ),
          ),
        ),
      ],
    );
  }
}
