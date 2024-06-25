import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:dpip/view/setting/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../global.dart';
import '../model/partial_earthquake_report.dart';
import '../widget/home_page_info.dart';
import '../widget/home_page_weather.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class Areas {
  static List<String> getOptions(currentArea) {
    return [currentArea]; // 鄉鎮列表
  }
}

// class IntColor {
//   static const Map<int, Color> _colors = {
//     0: Color(0xff202020),
//     1: Color(0xff003264),
//     2: Color(0xff0064c8),
//     3: Color(0xff1e9632),
//     4: Color(0xffffc800),
//     5: Color(0xffff9600),
//     6: Color(0xffff6400),
//     7: Color(0xffff0000),
//     8: Color(0xffc00000),
//     9: Color(0xff9600c8),
//   };
//
//   Color intColor(int intensity) {
//     return _colors[intensity] ?? Color(0xFF202020);
//   }
// }

class TemperatureColor {
  List<Color> tempColors = [
    const Color(0xFF006060),
    const Color(0xFF00AFAF),
    const Color(0xFF00FFFF),
    const Color(0xFF3AAA50),
    const Color(0xFFFFFF00),
    const Color(0xFFFF8A00),
    const Color(0xFFFF0000),
    const Color(0xFFFF00CA),
    const Color(0xFF6040B0),
  ];

  Color getTemperatureColor(double temperature) {
    const double minTemp = 5;
    const double maxTemp = 45;

    if (temperature == -99.9) {
      return const Color(0xFF808080);
    } else if (temperature <= minTemp) {
      return const Color(0xFF006060);
    } else if (temperature >= maxTemp) {
      return const Color(0xFF6040B0);
    } else {
      double t = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      int index = (t * (tempColors.length - 1)).floor();
      double localT = (t * (tempColors.length - 1)) - index;

      return Color.lerp(tempColors[index], tempColors[index + 1 < tempColors.length ? index + 1 : index], localT)!;
    }
  }
}

class _HomePage extends State<HomePage> with AutomaticKeepAliveClientMixin<HomePage> {
  late String _selectedArea;
  List<PartialEarthquakeReport> reports = [];
  var weather = {
    'temp': "-99.9",
    'feel': "-99.9",
    'humidity': "-99.9",
    'precip': "-99.9",
    'update': 0.0,
    'isday': 1,
    'condition': 0,
  };
  List eqReport = [];
  Map cityMaxInt = {};
  bool weatherRefreshing = true;
  bool eqReportRefreshing = true;
  bool cityIntRefreshing = true;
  late TemperatureColor tempToColor;
  final ScrollController _controller = ScrollController();
  var distCode = 100;
  String? currentCity = Global.preference.getString("loc-city");
  String? currentTown = Global.preference.getString("loc-town");
  String currentArea = "";

  Future<void> refreshWeather(context) async {
    setState(() {
      weatherRefreshing = true;
    });
    try {
      final distCode = Global.distCodeData[_selectedArea];
      final weatherData = await Global.api.getWeatherRealtime("$distCode");
      weather = {
        'temp': weatherData.temp.c.toString(),
        'feel': weatherData.feel.c.toString(),
        'humidity': weatherData.humidity.toString(),
        'precip': weatherData.precip.mm.toString(),
        'update': weatherData.update,
        'isday': weatherData.isDay.round(),
        'condition': weatherData.condition.round(),
      };
    } catch (e) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const CupertinoAlertDialog(
              content: Center(
                child: Text(
                  "取得天氣資料時發生錯誤",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '取得天氣資料時發生錯誤\n$e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xAA202020),
          ),
        );
      }
    }

    setState(() {
      weatherRefreshing = false;
    });
  }

  Future<void> getCityMaxInt() async {
    for (var i = 0; i < eqReport.length; i++) {
      cityMaxInt[eqReport[i].id] = await getCityInt(eqReport[i].id);
    }
    setState(() {
      cityIntRefreshing = false;
    });
  }

  Future<void> refreshEqReport(context) async {
    setState(() {
      eqReportRefreshing = true;
      cityIntRefreshing = true;
    });
    try {
      final eqReportData = await Global.api.getReportList(limit: 10);
      eqReport = eqReportData;
      getCityMaxInt();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '取得地震資料時發生錯誤\n$e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xAA202020),
        ),
      );
    }
    setState(() {
      eqReportRefreshing = false;
    });
  }

  getCityInt(id) async {
    final data = await Global.api.getReport(id);

    var report = data;
    var maxInt = 0;
    for (var city in report.list.entries) {
      if (_selectedArea.split(" ")[0] == city.key) {
        maxInt = city.value.intensity;
      }
    }
    return maxInt;
    // print(maxInt);
    // print(id);
  }

  void updateArea() {
    currentCity = Global.preference.getString("loc-city");
    currentTown = Global.preference.getString("loc-town");

    if (currentCity != null) {
      currentArea = "$currentCity $currentTown";
    } else {
      currentArea = "臺北市 中正區";
    }
    if (_selectedArea != currentArea && !Areas.getOptions(currentArea).toSet().contains(_selectedArea)) {
      _selectedArea = currentArea;
    }
  }

  void checkIsSetArea(context) {
    setState(() {});
    if (Global.preference.getString("loc-city") == null) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: const Text("尚未設定所在區域\n請前往設定",
                style: TextStyle(fontSize: 15),
              ),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const LocationSettingsPage(),
                      ),
                    );
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(24),
              content: const Text("尚未設定所在區域\n請前往設定"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationSettingsPage(),
                      ),
                    );
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void scrollToTop() {
    _controller.animateTo(
      0,
      duration: const Duration(seconds: 2),
      curve: Easing.standard,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tempToColor = TemperatureColor();
    _selectedArea = currentArea;
    updateArea();
    // _selectedArea = Areas.getOptions(currentArea).toSet().first;
    refreshWeather(context);
    refreshEqReport(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkIsSetArea(context);
    });
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.minScrollExtent) {
        setState(() {
          weatherRefreshing = false;
        });
      } else {
        setState(() {
          weatherRefreshing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (Platform.isIOS) {
      bool isIpad = MediaQuery.of(context).size.shortestSide >= 600;
      if (isIpad) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Padding(
                padding: const EdgeInsets.only(left: 48, right: 48),
                child: Row(
                  children: [
                    const Text(
                      "首頁",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        // onTap: () {
                        //   showCupertinoModalPopup(
                        //     context: context,
                        //     builder: (context) => Center(
                        //       child: SizedBox(
                        //         width: MediaQuery.of(context).size.width * 0.8,
                        //         child: CupertinoActionSheet(
                        //       message: SizedBox(
                        //         height: 200,
                        //         child: ListView(
                        //           shrinkWrap: true,
                        //           children: [
                        //             for (var item in Areas.getOptions(currentArea))
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   setState(() {
                        //                     _selectedArea = item;
                        //                   });
                        //                   refreshWeather(context);
                        //                   refreshEqReport(context);
                        //                   Navigator.of(context).pop(); // 關閉彈出視窗
                        //                 },
                        //                 child: Container(
                        //                   padding: const EdgeInsets.symmetric(vertical: 12),
                        //                   child: Text(
                        //                     item,
                        //                     textAlign: TextAlign.center,
                        //                     style: const TextStyle(fontSize: 20),
                        //                   ),
                        //                 ),
                        //               ),
                        //           ],
                        //         ),),),
                        //       ),
                        //     ),
                        //   );
                        // },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _selectedArea,
                              style: const TextStyle(fontSize: 28),
                            ),
                            // const Icon(CupertinoIcons.right_chevron),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Column(
              children: [
                HomePageWeather(weather: weather, weatherRefreshing: weatherRefreshing, tempToColor: tempToColor),
                Divider(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 2,
                      right: 10,
                      left: 10,
                      bottom: 55,
                    ),
                    child: eqReportRefreshing == false
                        ? eqReport.isEmpty
                            ? CustomScrollView(
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () async {
                                      await Future.wait([
                                        refreshWeather(context),
                                        refreshEqReport(context),
                                      ]);
                                    },
                                  ),
                                  const SliverToBoxAdapter(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "近期設定區域無地震或警特報資訊",
                                          style: TextStyle(
                                            fontSize: 16,
                                            letterSpacing: 2,
                                            color: Color(0xFFC9C9C9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : CustomScrollView(
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () async {
                                      updateArea();
                                      await Future.wait<void>([
                                        refreshWeather(context),
                                        refreshEqReport(context),
                                      ]);
                                    },
                                  ),
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return HomePageInfo(
                                          eqReport: eqReport[index],
                                          cityMaxInt: cityMaxInt,
                                          cityIntRefreshing: cityIntRefreshing,
                                        );
                                      },
                                      childCount: eqReport.length,
                                    ),
                                  ),
                                ],
                              )
                        : const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: [
                    const Text(
                      "首頁",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        // onTap: () {
                        //   showCupertinoModalPopup(
                        //     context: context,
                        //     builder: (context) => Center(
                        //       child: SizedBox(
                        //         width: MediaQuery.of(context).size.width * 0.8,
                        //         child: CupertinoActionSheet(
                        //       message: SizedBox(
                        //         height: 200,
                        //         child: ListView(
                        //           shrinkWrap: true,
                        //           children: [
                        //             for (var item in Areas.getOptions(currentArea))
                        //               GestureDetector(
                        //                 onTap: () {
                        //                   setState(() {
                        //                     _selectedArea = item;
                        //                   });
                        //                   refreshWeather(context);
                        //                   refreshEqReport(context);
                        //                   Navigator.of(context).pop(); // 關閉彈出視窗
                        //                 },
                        //                 child: Container(
                        //                   padding: const EdgeInsets.symmetric(vertical: 12),
                        //                   child: Text(
                        //                     item,
                        //                     textAlign: TextAlign.center,
                        //                     style: const TextStyle(fontSize: 20),
                        //                   ),
                        //                 ),
                        //               ),
                        //           ],
                        //         ),),),
                        //       ),
                        //     ),
                        //   );
                        // },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _selectedArea,
                              style: const TextStyle(fontSize: 20),
                            ),
                            // const Icon(CupertinoIcons.right_chevron),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Column(
              children: [
                HomePageWeather(weather: weather, weatherRefreshing: weatherRefreshing, tempToColor: tempToColor),
                Divider(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                      left: 10,
                      bottom: 70,
                    ),
                    child: eqReportRefreshing == false
                        ? eqReport.isEmpty
                            ? CustomScrollView(
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () async {
                                      await Future.wait([
                                        refreshWeather(context),
                                        refreshEqReport(context),
                                      ]);
                                    },
                                  ),
                                  const SliverToBoxAdapter(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "近期設定區域無地震或警特報資訊",
                                          style: TextStyle(
                                            fontSize: 16,
                                            letterSpacing: 2,
                                            color: Color(0xFFC9C9C9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : CustomScrollView(
                                slivers: [
                                  CupertinoSliverRefreshControl(
                                    onRefresh: () async {
                                      updateArea();
                                      await Future.wait<void>([
                                        refreshWeather(context),
                                        refreshEqReport(context),
                                      ]);
                                    },
                                  ),
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return HomePageInfo(
                                          eqReport: eqReport[index],
                                          cityMaxInt: cityMaxInt,
                                          cityIntRefreshing: cityIntRefreshing,
                                        );
                                      },
                                      childCount: eqReport.length,
                                    ),
                                  ),
                                ],
                              )
                        : const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return MediaQuery(
        // Set textScaleFactor to 1.0 to ignore system font size settings
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: SafeArea(
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
                  // DropdownButton<String>(
                  //   value: _selectedArea, // 當前選中的值
                  //   icon: const Icon(Icons.navigate_next), // 下拉箭頭圖標
                  //   onChanged: (String? newArea) {
                  //     setState(() {
                  //       _selectedArea = newArea!;
                  //     });
                  //     refreshWeather(context);
                  //     refreshEqReport(context);
                  //   },
                  //   items: Areas.getOptions(currentArea).toSet().map<DropdownMenuItem<String>>((String value) {
                  //     return DropdownMenuItem<String>(
                  //       value: value,
                  //       child: Text(
                  //         value,
                  //         style: const TextStyle(fontSize: 20),
                  //       ),
                  //     );
                  //   }).toList(),
                  // ),
                  Text(
                    _selectedArea,
                    style: const TextStyle(fontSize: 20),
                  )
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: context.colors.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            body: Column(
              children: [
                HomePageWeather(weather: weather, weatherRefreshing: weatherRefreshing, tempToColor: tempToColor),
                Container(
                  height: 1.5,
                  color: context.colors.onSurface,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: eqReportRefreshing == false
                        ? eqReport.isEmpty
                            ? RefreshIndicator(
                                onRefresh: () async {
                                  // 使用 Future.wait 來同時等待多個異步操作完成
                                  await Future.wait([
                                    refreshWeather(context),
                                    refreshEqReport(context),
                                  ]);
                                },
                                child: const SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "近期設定區域無地震或警特報資訊",
                                        style: TextStyle(
                                          fontSize: 16,
                                          letterSpacing: 2,
                                          color: Color(0xFFC9C9C9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // 使用 Future.wait 來同時等待多個異步操作完成
                                  await Future.wait([
                                    updateArea(),
                                    checkIsSetArea(context),
                                    refreshWeather(context),
                                    refreshEqReport(context),
                                  ] as Iterable<Future>);
                                },
                                child: ListView.builder(
                                  itemCount: eqReport.length,
                                  itemBuilder: (context, index) {
                                    return HomePageInfo(
                                      eqReport: eqReport[index],
                                      cityMaxInt: cityMaxInt,
                                      cityIntRefreshing: cityIntRefreshing,
                                    );
                                  },
                                  // shrinkWrap: true,
                                ),
                              )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
