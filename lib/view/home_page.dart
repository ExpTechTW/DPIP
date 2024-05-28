import 'dart:io';

import 'package:dpip/view/report_list.dart';
import 'package:dpip/view/weather_warning.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../global.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class Areas {
  static List<String> getOptions() {
    return ['萬榮鄉', '壽豐鄉', '花蓮市']; // 鄉鎮列表
  }
}

class Cal {
  double percentToPixel(double percent, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return percent / 100 * screenWidth;
  }
}

class _HomePage extends State<HomePage> {
  late String _selectedArea;
  var weather;
  double precip = 10.0; // 降水量
  int humidity = 99; // 濕度
  double feelslike = 27.9; // 體感
  // var temp; // 氣溫
  List temp_ = [];
  late Cal calculator;

  void refreshWeather() async {
    try {
      weather = await Global.api.getWeatherRealtime("100");
      print(weather);
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    calculator = Cal(); // 創建 Cal 類的一個實例
    refreshWeather();
    _selectedArea = Areas.getOptions().first; // 初始化時設定_selectedValue為列表的第一項
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const SafeArea(
        child: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "首頁",
                style: TextStyle(fontSize: 30, color: Color(0xFFFF9000), letterSpacing: 2),
              ),
            ],
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    "首頁",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedArea, // 當前選中的值
                    icon: const Icon(Icons.navigate_next), // 下拉箭頭圖標
                    onChanged: (String? newArea) {
                      setState(() {
                        _selectedArea = newArea!;
                      });
                    },
                    items: Areas.getOptions().map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: calculator.percentToPixel(60, context),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(height: calculator.percentToPixel(45, context)),
                      Positioned(
                        bottom: calculator.percentToPixel(0, context),
                        right: 0,
                        left: 0,
                        child: Column(
                          children: [
                            Container(
                              height: 30, //
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFFFFAA00),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: calculator.percentToPixel(8, context),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: calculator.percentToPixel(2, context)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("", style: TextStyle(fontSize: 12)),
                                    Text(
                                      "天氣資料來自 weather.com",
                                      style: TextStyle(fontSize: 12),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: calculator.percentToPixel(3, context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: calculator.percentToPixel(5, context)),
                              Icon(
                                Icons.cloud_outlined,
                                size: calculator.percentToPixel(35, context),
                              ),
                              SizedBox(width: calculator.percentToPixel(10, context)),
                              SizedBox(
                                width: calculator.percentToPixel(45, context),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("降水量", style: TextStyle(fontSize: 20)),
                                        Text("$precip mm",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("濕度", style: TextStyle(fontSize: 20)),
                                        Text("$humidity %",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("體感", style: TextStyle(fontSize: 20)),
                                        Text("$feelslike ℃",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("1.1".toString().split(".")[0],
                                            style: const TextStyle(
                                                fontSize: 96, fontWeight: FontWeight.w900, letterSpacing: 5)),
                                        Column(
                                          children: [
                                            const Text("℃",
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                            Text("." + "1.1".toString().split(".")[1],
                                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                                            SizedBox(height: calculator.percentToPixel(4.5, context)),
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
                          Container(
                            height: 1.5, // 横线高度
                            color: Colors.white,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: calculator.percentToPixel(5, context), right: calculator.percentToPixel(2, context)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "天氣警特報",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WeatherWarning(),
                                  ),
                                );
                              },
                              child: const Row(children: [
                                Text(
                                  "詳細資訊",
                                  style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
                                ),
                                Icon(
                                  Icons.navigate_next,
                                  color: Color(0xfff9f9f9),
                                ),
                              ]))
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "地震資訊",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReportList(),
                                  ),
                                );
                              },
                              child: const Row(children: [
                                Text(
                                  "詳細資訊",
                                  style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
                                ),
                                Icon(
                                  Icons.navigate_next,
                                  color: Color(0xfff9f9f9),
                                ),
                              ]))
                        ],
                      )
                    ],
                  ),
                )
              ],
            )),
      );
    }
  }
}
