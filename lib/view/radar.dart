import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/api.dart';

class Radar extends StatefulWidget {
  const Radar({Key? key}) : super(key: key);

  @override
  _RadarState createState() => _RadarState();
}

class _RadarState extends State<Radar> {
  late List<TimeOfDay> times;
  int selectedIndex = 0;
  int default_selectedIndex = 0;
  late ScrollController _scrollController;
  Color select_color = Colors.blueAccent;
  String url = "";

  @override
  void initState() {
    super.initState();
    String time_str = formatToUTC(adjustTime(TimeOfDay.now(), 10));
    url =
        "https://watch.ncdr.nat.gov.tw/00_Wxmap/7F13_NOWCAST/${time_str.substring(0, 6)}/${time_str.substring(0, 8)}/$time_str/nowcast_${time_str}_f00.png";
    DefaultCacheManager().emptyCache();
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    generateTimeList(now);
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    final pastTimes = times
        .where((time) => time.hour * 60 + time.minute <= currentTimeInMinutes)
        .toList();
    selectedIndex = times.indexOf(pastTimes.last);
    default_selectedIndex = selectedIndex;
    _scrollController =
        ScrollController(initialScrollOffset: selectedIndex * 75);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (int i = 0; i <= 11; i++) {
      String suffix = i.toString().padLeft(2, '0');
      String newUrl = url.replaceAll("f00", "f$suffix");
      precacheImage(CachedNetworkImageProvider(newUrl), context);
    }

    TimeOfDay init_time = adjustTime(TimeOfDay.now(), 20);
    for (int i = 0; i <= 14; i++) {
      String time_str = formatToUTC(init_time);
      String newUrl =
          "https://watch.ncdr.nat.gov.tw/00_Wxmap/7F13_NOWCAST/OBS/${time_str.substring(0, 6)}/${time_str.substring(0, 8)}/obs_$time_str.png";
      precacheImage(CachedNetworkImageProvider(newUrl), context);
      init_time = subtractTenMinutes(init_time);
    }
  }

  TimeOfDay subtractTenMinutes(TimeOfDay time) {
    DateTime now = DateTime.now();
    DateTime dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    DateTime newDateTime = dateTime.subtract(const Duration(minutes: 10));
    return TimeOfDay.fromDateTime(newDateTime);
  }

  void generateTimeList(DateTime now) {
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    const futureItemCount = 9;
    const pastItemCount = 18;
    const totalItemCount = futureItemCount + pastItemCount;

    times = List.generate(totalItemCount, (index) {
      int minutesToAdd;
      if (index < pastItemCount) {
        // 過去的選項
        minutesToAdd = (index - pastItemCount + 1) * 10;
      } else {
        // 未來的選項
        minutesToAdd = (index - pastItemCount + 1) * 10;
      }

      final totalMinutes =
          currentTime.hour * 60 + currentTime.minute + minutesToAdd;
      final roundedMinutes = (totalMinutes / 10).round() * 10;
      final newHour = roundedMinutes ~/ 60;
      final newMinute = roundedMinutes % 60;
      return TimeOfDay(hour: newHour % 24, minute: newMinute);
    });
  }

  bool SecondsEarlier(TimeOfDay checkTime, int sec) {
    final now = DateTime.now();
    final currentTimeOfDay = TimeOfDay.now();
    final currentDateTime = DateTime(now.year, now.month, now.day,
        currentTimeOfDay.hour, currentTimeOfDay.minute);
    final checkDateTime = DateTime(
        now.year, now.month, now.day, checkTime.hour, checkTime.minute);
    final difference = currentDateTime.difference(checkDateTime);
    return difference.inSeconds >= sec;
  }

  int compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) {
      return a.hour.compareTo(b.hour);
    }
    return a.minute.compareTo(b.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: const LatLng(23.6, 120.9),
                  zoom: 7.8,
                  minZoom: 6,
                  maxZoom: 10,
                  interactiveFlags:
                      InteractiveFlag.all - InteractiveFlag.rotate,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://api.mapbox.com/styles/v1/whes1015/clne7f5m500jd01re1psi1cd2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid2hlczEwMTUiLCJhIjoiY2xuZTRhbmhxMGIzczJtazN5Mzg0M2JscCJ9.BHkuZTYbP7Bg1U9SfLE-Cg",
                  ),
                  OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        bounds: LatLngBounds(
                          const LatLng(21.2446, 117.1595),
                          const LatLng(26.5153, 123.9804),
                        ),
                        imageProvider: CachedNetworkImageProvider(url),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100, // 可以調整這個高度以獲得所需的顯示效果
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: selectedIndex),
                itemExtent: 32.0, // 每個項目的高度
                onSelectedItemChanged: (index) {
                  int select_index = (default_selectedIndex - index - 1) * -1;
                  if (select_index < 0 ||
                      (index < default_selectedIndex &&
                          SecondsEarlier(times[index], 1200))) {
                    String time_str = formatToUTC(times[index]);
                    url =
                        "https://watch.ncdr.nat.gov.tw/00_Wxmap/7F13_NOWCAST/OBS/${time_str.substring(0, 6)}/${time_str.substring(0, 8)}/obs_$time_str.png";
                    select_color = Colors.blueAccent;
                  } else {
                    if (selectedIndex == 0 ||
                        compareTimeOfDay(times[index], TimeOfDay.now()) < 0) {
                      select_color = Colors.blueAccent;
                    } else {
                      select_color = Colors.purpleAccent;
                    }
                    String time_str =
                        formatToUTC(adjustTime(TimeOfDay.now(), 10));
                    url =
                        "https://watch.ncdr.nat.gov.tw/00_Wxmap/7F13_NOWCAST/${time_str.substring(0, 6)}/${time_str.substring(0, 8)}/$time_str/nowcast_${time_str}_f${select_index.toString().padLeft(2, "0")}.png";
                  }
                  setState(() {
                    selectedIndex = index;
                  });
                },
                children: List<Widget>.generate(times.length, (index) {
                  return Center(
                    child: Text(
                      times[index].format(context),
                      style: TextStyle(
                          fontSize: 24,
                          color: index == selectedIndex
                              ? select_color
                              : Colors.grey),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
