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

  HomePageWeather({
    super.key,
    required this.weather,
    required this.weatherRefreshing,
    required this.tempToColor,
  });

  Cal calculator = Cal();

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
                  SizedBox(
                    height: calculator.percentToPixel(45, context),
                  ),
                  Positioned(
                    bottom: calculator.percentToPixel(0.5, context),
                    right: 0,
                    left: 0,
                    child: Column(
                      children: [
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                CupertinoColors.systemBackground.resolveFrom(context),
                                tempToColor.getTemperatureColor(double.parse(weather["temp"] as String)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: calculator.percentToPixel(4, context),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: calculator.percentToPixel(5, context),
                              right: calculator.percentToPixel(5, context),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: calculator.percentToPixel(10, context),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(35, context),
                            child: Image.network(
                              'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                              width: calculator.percentToPixel(35, context),
                              height: calculator.percentToPixel(35, context),
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
                          SizedBox(
                            width: calculator.percentToPixel(0, context),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(50, context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: calculator.percentToPixel(13, context),
                                    ),
                                    SizedBox(
                                      width: calculator.percentToPixel(37, context),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "降水量",
                                                style: TextStyle(fontSize: 48),
                                              ),
                                              Text(
                                                "${weather["precip"]} mm",
                                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "濕度",
                                                style: TextStyle(fontSize: 48),
                                              ),
                                              Text(
                                                "${weather["humidity"]} %",
                                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "體感",
                                                style: TextStyle(fontSize: 48),
                                              ),
                                              Text(
                                                "${weather["feel"]} ℃",
                                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: calculator.percentToPixel(9.3, context),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      (weather["temp"] as String).split(".")[0],
                                      style: TextStyle(
                                        fontSize: 192,
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
                                          style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          ".${(weather["temp"] as String).split(".")[1]}",
                                          style: TextStyle(
                                            fontSize: 90,
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
                                        SizedBox(
                                          height: calculator.percentToPixel(1.8, context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(5, context),
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
                  SizedBox(
                    height: calculator.percentToPixel(45, context),
                  ),
                  Positioned(
                    bottom: calculator.percentToPixel(0, context),
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
                          height: calculator.percentToPixel(4, context),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: calculator.percentToPixel(5, context),
                              right: calculator.percentToPixel(5, context),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: calculator.percentToPixel(5, context),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(35, context),
                            child: Image.network(
                              'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                              width: calculator.percentToPixel(35, context),
                              height: calculator.percentToPixel(35, context),
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
                          SizedBox(
                            width: calculator.percentToPixel(0, context),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(55, context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: calculator.percentToPixel(10, context),
                                    ),
                                    SizedBox(
                                      width: calculator.percentToPixel(45, context),
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
                                        SizedBox(
                                          height: calculator.percentToPixel(3, context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: calculator.percentToPixel(5, context),
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
// height: calculator.percentToPixel(60, context),

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
                SizedBox(height: calculator.percentToPixel(45, context)),
                Positioned(
                  bottom: calculator.percentToPixel(0, context),
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
                              tempToColor.getTemperatureColor(double.parse(weather["temp"] as String)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: calculator.percentToPixel(6, context),
                        child: Padding(
                          padding: EdgeInsets.only(
                              bottom: calculator.percentToPixel(2, context),
                              left: calculator.percentToPixel(5, context),
                              right: calculator.percentToPixel(5, context),
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
                    SizedBox(height: calculator.percentToPixel(3, context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: calculator.percentToPixel(5, context)),
                        // Icon(
                        //   weatherIcon.getWeatherIcon(weather["isday"], weather["condition"]),
                        //   size: calculator.percentToPixel(35, context),
                        // ),
                        SizedBox(
                          width: calculator.percentToPixel(35, context),
                          child: Image.network(
                            'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                            width: calculator.percentToPixel(35, context),
                            height: calculator.percentToPixel(35, context),
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
                        SizedBox(width: calculator.percentToPixel(0, context)),
                        SizedBox(
                          width: calculator.percentToPixel(55, context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: calculator.percentToPixel(10, context),
                                  ),
                                  SizedBox(
                                    width: calculator.percentToPixel(45, context),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("降水量", style: TextStyle(fontSize: 20)),
                                            Text(
                                              "${weather["precip"]} mm",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("濕度", style: TextStyle(fontSize: 20)),
                                            Text(
                                              "${weather["humidity"]} %",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("體感", style: TextStyle(fontSize: 20)),
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
                                      SizedBox(
                                        height: calculator.percentToPixel(4.5, context),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: calculator.percentToPixel(5, context)),
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
