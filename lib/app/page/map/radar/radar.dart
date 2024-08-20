import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RadarMap extends StatelessWidget {
  final int selectedTime;

  const RadarMap({Key? key, required this.selectedTime}) : super(key: key);

  String _formatTime(int unixTime) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('顯示時間: ${_formatTime(selectedTime)}'),
          Text('Unix 時間戳: $selectedTime'),
        ],
      ),
    );
  }
}