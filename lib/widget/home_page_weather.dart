import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../view/home_page.dart';

class HomePageWeather extends StatelessWidget {
  final Map weather;
  final bool weatherRefreshing;
  final TemperatureColor tempToColor;

  const HomePageWeather({
    super.key,
    required this.weather,
    required this.weatherRefreshing,
    required this.tempToColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      bool isIpad = MediaQuery.of(context).size.shortestSide >= 600;
      if (isIpad) {
        return Stack(
          children: [
            if (weatherRefreshing && weather["temp"] != "-99.9")
              const Positioned.fill(
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
            if (weather["temp"] == "-99.9")
              const Positioned.fill(
                child: Center(
                  child: Text("天氣取得失敗"),
                ),
              ),
            Container(),
            Opacity(
              opacity: weatherRefreshing || weather["temp"] == "-99.9" ? 0 : 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Column(
                      children: [
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                CupertinoColors.systemBackground.resolveFrom(context),
                                tempToColor.getTemperatureColor(
                                  double.parse(weather["temp"] as String),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 31,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 55,
                              right: 60,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "更新時間：${DateFormat("MM/dd HH:mm").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      (weather["update"] as double).round() * 1000,
                                    ),
                                  )}",
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const Text(
                                  "天氣資料來自 weather.com",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 58),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 10,
                            child: Container(),
                          ),
                          Flexible(
                            flex: 60,
                            child: Image.network(
                              'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                              width: 332,
                              height: 332,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CupertinoActivityIndicator(),
                                );
                              },
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Container();
                              },
                            ),
                          ),
                          Flexible(
                            flex: 130,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 15,
                                      child: Container(),
                                    ),
                                    Flexible(
                                      flex: 40,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "降水量",
                                                style: TextStyle(fontSize: 45),
                                              ),
                                              Text(
                                                "${weather["precip"]} mm",
                                                style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "濕度",
                                                style: TextStyle(fontSize: 45),
                                              ),
                                              Text(
                                                "${weather["humidity"]} %",
                                                style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "體感",
                                                style: TextStyle(fontSize: 45),
                                              ),
                                              Text(
                                                "${weather["feel"]} ℃",
                                                style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      (weather["temp"] as String).split(".")[0],
                                      style: TextStyle(
                                        fontSize: 180,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 5,
                                        color: Color.lerp(
                                            CupertinoColors.label.resolveFrom(context), const Color(0xFFFFFFFF), 0.1),
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(5, 5),
                                            blurRadius: 20,
                                            color: Color.fromARGB(120, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "℃",
                                          style: TextStyle(fontSize: 58, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          ".${(weather["temp"] as String).split(".")[1]}",
                                          style: TextStyle(
                                            fontSize: 88,
                                            fontWeight: FontWeight.w900,
                                            color: Color.lerp(CupertinoColors.label.resolveFrom(context),
                                                const Color(0xFFFFFFFF), 0.1),
                                            shadows: const [
                                              Shadow(
                                                offset: Offset(5, 5),
                                                blurRadius: 20,
                                                color: Color.fromARGB(120, 0, 0, 0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 25,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ],
        );
      } else {
        return Stack(
          children: [
            if (weatherRefreshing && weather["temp"] != "-99.9")
              const Positioned.fill(
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
            if (weather["temp"] == "-99.9")
              const Positioned.fill(
                child: Center(
                  child: Text("天氣取得失敗"),
                ),
              ),
            Container(),
            Opacity(
              opacity: weatherRefreshing || weather["temp"] == "-99.9" ? 0 : 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Column(
                      children: [
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                CupertinoColors.systemBackground.resolveFrom(context),
                                tempToColor.getTemperatureColor(
                                  double.parse(weather["temp"] as String),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 0,
                              left: 25,
                              right: 25,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "更新時間：${DateFormat("MM/dd HH:mm").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      (weather["update"] as double).round() * 1000,
                                    ),
                                  )}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Text(
                                  "天氣資料來自 weather.com",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 105),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 5,
                            child: Container(),
                          ),
                          Flexible(
                            flex: 40,
                            child: Image.network(
                              'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                              width: 142,
                              height: 142,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CupertinoActivityIndicator(),
                                );
                              },
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Container();
                              },
                            ),
                          ),
                          Flexible(
                            flex: 55,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 10,
                                      child: Container(),
                                    ),
                                    Flexible(
                                      flex: 60,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "降水量",
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              Text(
                                                "${weather["precip"]} mm",
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "濕度",
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              Text(
                                                "${weather["humidity"]} %",
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "體感",
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              Text(
                                                "${weather["feel"]} ℃",
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      (weather["temp"] as String).split(".")[0],
                                      style: TextStyle(
                                        fontSize: 96,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 5,
                                        color: Color.lerp(
                                            CupertinoColors.label.resolveFrom(context), const Color(0xFFFFFFFF), 0.1),
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(5, 5),
                                            blurRadius: 20,
                                            color: Color.fromARGB(120, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "℃",
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          ".${(weather["temp"] as String).split(".")[1]}",
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            color: Color.lerp(CupertinoColors.label.resolveFrom(context),
                                                const Color(0xFFFFFFFF), 0.1),
                                            shadows: const [
                                              Shadow(
                                                offset: Offset(5, 5),
                                                blurRadius: 20,
                                                color: Color.fromARGB(120, 0, 0, 0),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 5,
                            child: Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }
    } else {
      return Stack(
        children: [
          weatherRefreshing == true
              ? const Positioned.fill(
                  child: Center(
                  child: CircularProgressIndicator(),
                ))
              : weather["temp"] == "-99.9"
                  ? const Positioned.fill(
                      child: Center(
                      child: Text("天氣取得失敗"),
                    ))
                  : Container(),
          Opacity(
            opacity: weatherRefreshing == true || weather["temp"] == "-99.9" ? 0 : 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              context.colors.surface,
                              tempToColor.getTemperatureColor(
                                double.parse(weather["temp"] as String),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                            left: 25,
                            right: 25,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "更新時間：${DateFormat("MM/dd HH:mm").format(
                                  TZDateTime.fromMillisecondsSinceEpoch(
                                    getLocation("Asia/Taipei"),
                                    (weather["update"] as double).round() * 1000,
                                  ),
                                )}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              const Text(
                                "天氣資料來自 weather.com",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 5,
                          child: Container(),
                        ),
                        Flexible(
                          flex: 35,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                              // width: 128,
                              // height: 128,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                return Container();
                              },
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 55,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    flex: 10,
                                    child: Container(),
                                  ),
                                  Flexible(
                                    flex: 45,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "降水量",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            Text(
                                              "${weather["precip"]} mm",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "濕度",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            Text(
                                              "${weather["humidity"]} %",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "體感",
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            Text(
                                              "${weather["feel"]} ℃",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (weather["temp"] as String).split(".")[0],
                                    style: TextStyle(
                                      fontSize: 96,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 5,
                                      color: Color.lerp(context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(5, 5),
                                          blurRadius: 20,
                                          color: Color.fromARGB(120, 0, 0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "℃",
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        ".${(weather["temp"] as String).split(".")[1]}",
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: Color.lerp(context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
                                          shadows: const [
                                            Shadow(
                                              offset: Offset(5, 5),
                                              blurRadius: 20,
                                              color: Color.fromARGB(120, 0, 0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          flex: 5,
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
