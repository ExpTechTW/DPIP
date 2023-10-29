import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as HTTP;

import '../core/api.dart';
import 'report.dart';

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({Key? key}) : super(key: key);

  @override
  _EarthquakePage createState() => _EarthquakePage();
}

var data;
List<Color> intensity_back = const [
  Color(0xff6B7878),
  Color(0xff1E6EE6),
  Color(0xff32B464),
  Color(0xffFFE05D),
  Color(0xffFFAA13),
  Color(0xffEF700F),
  Color(0xffE60000),
  Color(0xffA00000),
  Color(0xff5D0090),
];
List<Color> intensity_font = [
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.black,
  Colors.black,
  Colors.black,
  Colors.white,
  Colors.white,
  Colors.white,
];

class _EarthquakePage extends State<EarthquakePage> {
  String url = 'https://api.exptech.com.tw/api/v1/trem/rts-image/';
  String eew_url = "https://api.exptech.com.tw/api/v1/eq/eew/";
  late Widget _pic = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  late final Widget _taiwan = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  late final Widget _int = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  int replay = 0;
  var clock;
  var ntp_clock;
  int time_ntp = 0;
  int time_local = 0;

  int _page = 0;
  List<Widget> _List_children = <Widget>[];

  void ntp() async {
    var ans = await get("https://api.exptech.com.tw/api/v1/ntp");
    if (ans != false) {
      time_ntp = ans["time"] - 1000;
      time_local = DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  void initState() {
    ntp();
    ntp_clock = Timer.periodic(const Duration(seconds: 60), (timer) {
      ntp();
    });
    render();
    super.initState();
  }

  _updateImgWidget() async {
    try {
      if (replay != 0) replay += 1000;
      DateTime now = (replay != 0)
          ? DateTime.fromMillisecondsSinceEpoch(replay)
              .toUtc()
              .add(const Duration(hours: 8))
          : DateTime.fromMillisecondsSinceEpoch(((time_ntp +
                          (DateTime.now().millisecondsSinceEpoch -
                              time_local -
                              1000)) ~/
                      1000) *
                  1000)
              .toUtc()
              .add(const Duration(hours: 8));

      String YYYY = now.year.toString();
      String MM = now.month.toString().padLeft(2, '0');
      String DD = now.day.toString().padLeft(2, '0');
      String hh = now.hour.toString().padLeft(2, '0');
      String mm = now.minute.toString().padLeft(2, '0');
      String ss = now.second.toString().padLeft(2, '0');

      String Now = '$YYYY$MM$DD$hh$mm$ss';

      print(Now);

      Uint8List bytes = await HTTP
          .readBytes(Uri.parse(url + Now))
          .timeout(const Duration(seconds: 1));
      _pic = Image.memory(bytes, gaplessPlayback: true);
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    if (clock != null) clock.cancel();
    if (ntp_clock != null) ntp_clock.cancel();
    super.dispose();
  }

  Future<void> render() async {
    if (clock != null && _page != 0) {
      clock.cancel();
      clock = null;
    }
    if (_page == 0 && clock == null) {
      clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
        await _updateImgWidget();
        render();
      });
    }
    data ??=
        await get("https://exptech.com.tw/api/v1/earthquake/reports?limit=50");
    _List_children = <Widget>[];
    if (_page == 0) {
      _List_children.add(Padding(
        padding: const EdgeInsets.all(5),
        child: Stack(alignment: Alignment.center, children: [
          _taiwan,
          _pic,
          _int,
        ]),
      ));
      _List_children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "強震即時警報",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "2023年10月15日 10:15 發震",
                          style: TextStyle(
                            color: Colors.grey[400], // Slightly brighter
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(5), // Added margin
                    decoration: BoxDecoration(
                      color: const Color(0xFFD90000), // Slightly adjusted color
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Text(
                          "慎防強烈搖晃",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      _List_children.add(Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEA0000),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text("預估本地震度",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("4",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 45,
                                  fontWeight: FontWeight.w900)),
                          Text("級",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 60, // Adjust as needed
                  width: 1,
                  color: Colors.white,
                  margin: const EdgeInsets.only(left: 10, right: 10),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text("剩餘抵達時間",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("10",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 45)),
                          Text(".1 秒",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
      _List_children.add(
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff333439),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "震央位置",
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "臺灣東部海域",
                    style: TextStyle(fontSize: 22, color: Colors.grey[300]),
                  ),
                ),
                ListTile(
                  title: Text(
                    "規模",
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "M7.4",
                    style: TextStyle(fontSize: 22, color: Colors.grey[300]),
                  ),
                ),
                ListTile(
                  title: Text(
                    "深度",
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "10km",
                    style: TextStyle(fontSize: 22, color: Colors.grey[300]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_page == 1) {
      if (data == null) {
        _List_children.add(const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "服務異常",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w100, color: Colors.red),
            ),
            Text(
              "稍等片刻後重試 如持續異常 請回報開發人員",
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          ],
        ));
      } else {
        for (var i = 0; i < data.length; i++) {
          int level = data[i]["data"][0]["areaIntensity"];
          String Lv_str = int_to_str_en(level);
          _List_children.add(
            Card(
              color: const Color(0xff333439),
              margin: const EdgeInsets.all(5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: InkWell(
                onTap: () {
                  ReportPage.data = data[i];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPage(),
                      ),
                  );
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: intensity_back[level - 1],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            Lv_str,
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.w600,
                              color: intensity_font[level - 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 75, right: 15),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data[i]["location"]
                                .substring(data[i]["location"].indexOf("(") + 1,
                                    data[i]["location"].indexOf(")"))
                                .replaceAll("位於", ""),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          Text(
                            data[i]["originTime"].toString().substring(0, 16),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        "M ${data[i]["magnitudeValue"].toStringAsFixed(1)}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              )
            ),
          );
        }
      }
    } else {
      _List_children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "關於強震監視器",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "強震監視器是由 TREM(臺灣即時地震監測) 觀測到 全臺 現在的震動 做為即時震度顯示的功能。",
                style: TextStyle(color: Colors.grey[300], fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                "· 地震發生當下，可以透過站點顏色變化，觀察地震波傳播情形。",
                style: TextStyle(color: Colors.grey[500], fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "· 中央氣象署 發布 強震即時警報(地震速報) 後，圖層上會顯示出 P波(藍色) S波(紅色) 的預估地震波傳播狀況。",
                style: TextStyle(color: Colors.grey[500], fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "· 顯示的實時震度不是 中央氣象署 所提供的資料，因此可能與 中央氣象署 觀測到的震度不一致，應以 中央氣象署 公布之資訊為主。",
                style: TextStyle(color: Colors.grey[500], fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "· 由於 日常雜訊(汽車、工廠、施工等) 影響，平時站點可能也會有顏色變化。另外，由於是即時資料，當下無法判斷是否是故障，所以也有可能因為站點故障而改變顏色。",
                style: TextStyle(color: Colors.grey[500], fontSize: 18),
              ),
              const SizedBox(height: 40),
              const Text(
                "關於 TREM-Net",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "2022年6月初 開始於全臺各地部署站點，TREM-Net(TREM地震觀測網) 由兩個觀測網組成，分別為SE-Net(強震觀測網「加速度儀」)及MS-Net(微震觀測網「速度儀」)，共同紀錄地震時的各項數據。",
                style: TextStyle(color: Colors.grey[300], fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }
    if (mounted) setState(() {});
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                if (_page == 0) {
                  _page = 1;
                  render();
                } else if (_page == 2) {
                  _page = 0;
                  render();
                }
              } else if (details.primaryVelocity! < 0) {
                if (_page == 1) {
                  _page = 0;
                  render();
                } else if (_page == 0) {
                  _page = 2;
                  render();
                }
              }
            },
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_page == 1)
                            ? Colors.blue[800]
                            : Colors.transparent,
                        elevation: 20,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        _page = 1;
                        render();
                      },
                      child: const Text(
                        "地震報告",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_page == 0)
                            ? Colors.blue[800]
                            : Colors.transparent,
                        elevation: 20,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        _page = 0;
                        render();
                      },
                      child: const Text(
                        "強震監視器",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_page == 2)
                            ? Colors.blue[800]
                            : Colors.transparent,
                        elevation: 20,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        _page = 2;
                        render();
                      },
                      child: const Text(
                        "關於",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      data = null;
                      await render();
                    },
                    child: ListView(
                        physics: const ClampingScrollPhysics(),
                        children: _List_children.toList()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
