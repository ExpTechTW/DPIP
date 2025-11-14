import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class TsunamiEstimateList extends StatelessWidget {
  final List tsunamiList;

  const TsunamiEstimateList({super.key, required this.tsunamiList});

  String convertTimestamp(int timestamp) {
    final location = tz.getLocation('Asia/Taipei');
    final DateTime dateTime = tz.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);

    final DateFormat formatter = DateFormat('d日HH:mm');
    final String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }

  String heightToString(height) {
    if (height == 3) {
      return '>3m';
    } else if (height == 2) {
      return '1~3m';
    } else if (height == 1) {
      return '0.3~1m';
    } else {
      return '<0.3m';
    }
  }

  Color heightToColor(height) {
    if (height == 3) {
      return const Color(0xFFE543FF);
    } else if (height == 2) {
      return const Color(0xFFC90000);
    } else if (height == 1) {
      return const Color(0xFFFFC900);
    } else {
      return const Color(0xFF00AAFF);
    }
  }

  Color heightToTextColor(height) {
    if (height == 1) {
      return const Color(0xFF202020);
    } else {
      return const Color(0xFFFFFFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tsunamiList.map((item) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.area, style: const TextStyle(fontSize: 18, letterSpacing: 2)),
                Row(
                  children: [
                    Text(convertTimestamp(item.arrivalTime), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: heightToColor(item.waveHeight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: 75,
                      child: Center(
                        child: Text(
                          heightToString(item.waveHeight),
                          style: TextStyle(
                            color: heightToTextColor(item.waveHeight),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }
}
