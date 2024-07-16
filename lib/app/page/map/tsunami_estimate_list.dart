import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TsunamiEstimateList extends StatelessWidget {
  final List tsunamiList;

  const TsunamiEstimateList({
    super.key,
    required this.tsunamiList,
  });

  convertTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    DateFormat formatter = DateFormat('dd日HH:mm');
    String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }

  heightToString(height) {
    if (height == 3) {
      return ">6m";
    } else if (height == 2) {
      return "3~6m";
    } else if (height == 1) {
      return "1~3m";
    } else {
      return "<1m";
    }
  }

  heightToColor(height) {
    if (height >= 2) {
      return const Color(0xFFE543FF);
    } else if (height == 1) {
      return const Color(0xFFC90000);
    } else {
      return const Color(0xFFFFC900);
    }
  }

  heightToTextColor(height) {
    if (height >= 1) {
      return const Color(0xFFFFFFFF);
    } else {
      return const Color(0xFF202020);
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.area,
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      convertTimestamp(item.arrivalTime),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: heightToColor(item.waveHeight),
                        borderRadius: BorderRadius.circular(8), // 設置圓角半徑
                      ),
                      width: 75,
                      height: 25,
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
            const SizedBox(
              height: 4,
            )
          ],
        );
      }).toList(),
    );
  }
}
