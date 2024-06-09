import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:dpip/view/report.dart';
import 'package:dpip/view/setting/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../core/utils.dart';
import '../global.dart';
import '../model/partial_earthquake_report.dart';
import '../util/dist_code.dart';
import '../util/intensity_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class Areas {
  static List<String> getOptions(currentArea) {
    return [currentArea, '花蓮縣 萬榮鄉', '臺北市 中正區']; // 鄉鎮列表
  }
}

class Cal {
  double percentToPixel(double percent, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return percent / 100 * screenWidth;
  }
}

Future<int?> getZipCodeForArea(String area) async {
  final data = await DistCodeUtil.readJsonFile();
  return DistCodeUtil.getZipCode(area, data);
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

class TempColor {
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

  Color getColorForTemp(double temp) {
    const double minTemp = 5;
    const double maxTemp = 45;

    if (temp == -99.9) {
      return const Color(0xFF808080);
    } else if (temp <= minTemp) {
      return const Color(0xFF006060);
    } else if (temp >= maxTemp) {
      return const Color(0xFF6040B0);
    } else {
      double t = ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      int index = (t * (tempColors.length - 1)).floor();
      double localT = (t * (tempColors.length - 1)) - index;

      return Color.lerp(tempColors[index], tempColors[index + 1 < tempColors.length ? index + 1 : index], localT)!;
    }
  }
}

class EqInfo extends StatelessWidget {
  // final List eqReport;
  //
  // const EqInfo({Key? key, required this.eqReport}) : super(key: key);
  final PartialEarthquakeReport eqReport;

  final Map cityMaxInt;

  final bool cityIntRefreshing;

  EqInfo({super.key, required this.cityMaxInt, required this.eqReport, required this.cityIntRefreshing});

  Cal calculator = Cal();

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ReportPage(report: eqReport),
                ),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0x50808080),
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.02,
                        decoration: BoxDecoration(
                          color: eqReport.hasNumber ? const Color(0x99FFB400) : const Color(0x9919C8C8),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: calculator.percentToPixel(5, context),
                        right: calculator.percentToPixel(5, context),
                        top: calculator.percentToPixel(1, context),
                        bottom: calculator.percentToPixel(2, context),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: calculator.percentToPixel(1, context),
                              bottom: calculator.percentToPixel(2, context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                Text(
                                  DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      eqReport.time,
                                    ),
                                  ),
                                  // style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),
                                  style: TextStyle(
                                      color: Color.lerp(
                                          CupertinoColors.label.resolveFrom(context), const Color(0xFF808080), 0.5),
                                      fontSize: 16),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width * 0.12,
                                height: MediaQuery.of(context).size.width * 0.12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: context.colors.intensity(eqReport.intensity),
                                ),
                                child: Text(
                                  intensityToNumberString(eqReport.intensity),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(eqReport.intensity),
                                  ),
                                ),
                              ),
                              cityIntRefreshing == true
                                  ? Container(
                                alignment: Alignment.center,
                                width: calculator.percentToPixel(8, context),
                                height: calculator.percentToPixel(8, context),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                    color: const Color(0xFF202020)),
                                child: Text(
                                  "--",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(0),
                                  ),
                                ),
                              )
                                  : Container(
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width * 0.08,
                                height: MediaQuery.of(context).size.width * 0.08,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                  color: cityMaxInt[eqReport.id] == 0
                                      ? const Color(0xFF202020)
                                      : context.colors.intensity(cityMaxInt[eqReport.id]),
                                ),
                                child: Text(
                                  intensityToNumberString(cityMaxInt[eqReport.id]),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(cityMaxInt[eqReport.id]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.01,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(report: eqReport),
                ),
              );
            },
            child: Container(
              width: calculator.percentToPixel(90, context),
              // height: calculator.percentToPixel(25, context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0x30808080),
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: calculator.percentToPixel(2, context),
                        decoration: BoxDecoration(
                          color: eqReport.hasNumber ? const Color(0x99FFB400) : const Color(0x9919C8C8),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: calculator.percentToPixel(5, context),
                        right: calculator.percentToPixel(2, context),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: calculator.percentToPixel(1, context),
                              bottom: calculator.percentToPixel(2, context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                Text(
                                  DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      eqReport.time,
                                    ),
                                  ),
                                  // style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),

                                  style: TextStyle(
                                      color: Color.lerp(context.colors.onSurface, const Color(0xFF808080), 0.5),
                                      fontSize: 16),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: calculator.percentToPixel(12, context),
                                height: calculator.percentToPixel(12, context),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: context.colors.intensity(eqReport.intensity),
                                ),
                                child: Text(
                                  intensityToNumberString(eqReport.intensity),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(eqReport.intensity),
                                  ),
                                ),
                              ),
                              cityIntRefreshing == true
                                  ? Container(
                                alignment: Alignment.center,
                                width: calculator.percentToPixel(8, context),
                                height: calculator.percentToPixel(8, context),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                    color: const Color(0xFF202020)),
                                child: Text(
                                  "--",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(0),
                                  ),
                                ),
                              )
                                  : Container(
                                alignment: Alignment.center,
                                width: calculator.percentToPixel(8, context),
                                height: calculator.percentToPixel(8, context),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                  color: cityMaxInt[eqReport.id] == 0
                                      ? const Color(0xFF202020)
                                      : context.colors.intensity(cityMaxInt[eqReport.id]),
                                ),
                                child: Text(
                                  intensityToNumberString(cityMaxInt[eqReport.id]),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: context.colors.onIntensity(cityMaxInt[eqReport.id]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: calculator.percentToPixel(2, context),
          ),
        ],
      );
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
  late Cal calculator;
  late TempColor tempToColor;
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
      distCode = (await getZipCodeForArea(_selectedArea))!;
      final weatherData = await Global.api.getWeatherRealtime("$distCode");
      weather = {
        'temp': weatherData.temp.c.toString(),
        'feel': weatherData.feel.c.toString(),
        'humidity': weatherData.humidity.toString(),
        'precip': weatherData.precip.mm.toString(),
        'update': weatherData.update,
        'isday': weatherData.isday.round(),
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
    if (_selectedArea != currentArea) {
      _selectedArea = currentArea;
    }
  }

  void checkIsSetArea(context) {
    setState(() {});
    if (Global.preference.getString("loc-city") == null) {
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
          });
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
    tempToColor = TempColor();
    calculator = Cal();
    _selectedArea = "";
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
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Row(
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
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          message: SizedBox(
                            height: 200,
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (var item in Areas.getOptions(currentArea))
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedArea = item;
                                      });
                                      refreshWeather(context);
                                      refreshEqReport(context);
                                      Navigator.of(context).pop(); // 關閉彈出視窗
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        item,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _selectedArea,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Icon(CupertinoIcons.right_chevron),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(controller: _controller, slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.wait([
                    refreshWeather(context),
                    refreshEqReport(context),
                  ]);
                },
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Stack(
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
                                            tempToColor.getColorForTemp(double.parse(weather["temp"] as String)),
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
                                          loadingBuilder:
                                              (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CupertinoActivityIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (BuildContext context, Object exception, StackTrace? stackTrace) {
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
                                                          const Text("降水量", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["precip"]} mm",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text("濕度", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["humidity"]} %",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text("體感", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["feel"]} ℃",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
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
                                                    color:
                                                    Color.lerp(context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
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
                                                        color: Color.lerp(
                                                            context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
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
                    ),
                    Divider(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ],
                ),
              ),
              eqReportRefreshing == false
                  ? eqReport.isEmpty
                  ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: calculator.percentToPixel(5, context),
                    right: calculator.percentToPixel(5, context),
                    top: calculator.percentToPixel(5, context),
                  ),
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "近期設定區域無地震或警特報資訊",
                          style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    return EqInfo(
                      eqReport: eqReport[index],
                      cityMaxInt: cityMaxInt,
                      cityIntRefreshing: cityIntRefreshing,
                    );
                  },
                  childCount: eqReport.length,
                ),
              )
                  : const SliverFillRemaining(
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
            ]),
          ),
        ),
      );
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
                  DropdownButton<String>(
                    value: _selectedArea, // 當前選中的值
                    icon: const Icon(Icons.navigate_next), // 下拉箭頭圖標
                    onChanged: (String? newArea) {
                      setState(() {
                        _selectedArea = newArea!;
                      });
                      refreshWeather(context);
                      refreshEqReport(context);
                    },
                    items: Areas.getOptions(currentArea).toSet().map<DropdownMenuItem<String>>((String value) {
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
                  color: context.colors.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            body: Column(
              children: [
                Stack(
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
                                        tempToColor.getColorForTemp(double.parse(weather["temp"] as String)),
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
                                        right: calculator.percentToPixel(5, context)),
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
                                      loadingBuilder:
                                          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
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
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("濕度", style: TextStyle(fontSize: 20)),
                                                      Text(
                                                        "${weather["humidity"]} %",
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("體感", style: TextStyle(fontSize: 20)),
                                                      Text(
                                                        "${weather["feel"]} ℃",
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                                color:
                                                Color.lerp(context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
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
                                                    color: Color.lerp(
                                                        context.colors.onSurface, const Color(0xFFFFFFFF), 0.1),
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
                ),
                Container(
                  height: 1.5,
                  color: context.colors.onSurface,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: calculator.percentToPixel(5, context),
                      right: calculator.percentToPixel(5, context),
                      top: calculator.percentToPixel(5, context),
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
                              style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
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
                          return EqInfo(
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
