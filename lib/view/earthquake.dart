import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/view/about_rts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils.dart';

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({super.key});

  @override
  State<EarthquakePage> createState() => _EarthquakePage();
}

int randomNum(int max) {
  return Random().nextInt(max) + 1;
}

class _EarthquakePage extends State<EarthquakePage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  AppLifecycleState? _notification;
  String url = 'https://lb-${randomNum(4)}.exptech.com.tw/api/v1/trem/rts-image';
  String eewUrl = "https://api-2.exptech.com.tw/api/v1/eq/eew?type=cwa";
  Widget _pic = Image.network("https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  final Widget _taiwan = Image.network("https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  final Widget _int = Image.network("https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  late Timer clock;
  late Timer ntpClock;
  int timeNtp = 0;
  int timeLocal = 0;
  var region;

  var eewData = {};
  String eewID = "";
  String eewTime = "";
  double sArrive = 0;
  double pArrive = 0;
  int userIntensity = 0;
  String city = "";
  String town = "";

  bool loading = true;
  Widget? stack;

  void ntp() async {
    var ans = await get("https://lb-${randomNum(4)}.exptech.com.tw/ntp");
    if (ans != false) {
      timeNtp = ans - 1000;
      timeLocal = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<void> updateImage() async {
    try {
      if (_notification != null && _notification != AppLifecycleState.resumed) return;

      Uint8List bytes = await http.readBytes(Uri.parse(url)).timeout(const Duration(seconds: 1));

      _pic = Image.memory(bytes, gaplessPlayback: true);

      setState(() {
        stack = Stack(
          alignment: Alignment.center,
          children: [
            _taiwan,
            _pic,
            _int,
          ],
        );
      });
    } catch (e) {
      return;
    }
  }

  Future<void> updateEEW() async {
    try {
      if (_notification != null && _notification != AppLifecycleState.resumed) return;

      final response = await http.get(Uri.parse(eewUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data.length != 0) {
          eewData = data[0];
          DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(eewData["eq"]["time"]);
          DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm:ss');
          eewTime = formatter.format(dateTime);

          var eew_pga = eewAreaPga(eewData["eq"]["lat"], eewData["eq"]["lon"], eewData["eq"]["depth"].toDouble(),
              eewData["eq"]["mag"].toDouble(), region);

          if (eewID != eewData["id"].toString() + eewData["serial"].toString()) {
            eewID = eewData["id"].toString() + eewData["serial"].toString();

            userIntensity = intensityFloatToInt(eew_pga["$city $town"]["i"]);

            var Speed = speed(
                eewData["eq"]["depth"].toDouble(),
                distance(
                    eewData["eq"]["lat"], eewData["eq"]["lon"], region[city][town]["lat"], region[city][town]["lon"]));

            sArrive = eewData["eq"]["time"] + Speed["Stime"]! * 1000;
            pArrive = eewData["eq"]["time"] + Speed["Ptime"]! * 1000;
          }
        } else {
          eewID = "";
        }
      } else {
        throw Exception('The server returned a status code of ${response.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  get wantKeepAlive => true;

  Future<void> start() async {
    region = json.decode(await rootBundle.loadString('assets/region.json'));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    city = prefs.getString("loc-city") ?? "";
    town = prefs.getString("loc-town") ?? "";
  }

  @override
  void initState() {
    super.initState();
    start();
    WidgetsBinding.instance.addObserver(this);

    ntp();
    ntpClock = Timer.periodic(const Duration(seconds: 60), (timer) {
      ntp();
    });

    clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
      updateImage();
      updateEEW();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
    });
  }

  @override
  void dispose() {
    clock.cancel();
    ntpClock.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("強震監視器"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.question_circle),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return const AboutRts();
                  },
                ),
              );
            },
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "即時資料僅供參考\n實際請以中央氣象署的資料為主",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: stack != null
                      ? ClipRRect(
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            maxScale: 10,
                            child: stack!,
                          ),
                        )
                      : const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                ),
                Container(
                  child: (eewID != "")
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: (eewData["eq"]["max"] > 4) ? Colors.red : Colors.orange,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: double.infinity),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text((eewData["eq"]["max"] > 4) ? "緊急地震速報" : "地震速報",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                                        Text("#${eewData["serial"]}",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300))
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(eewData["eq"]["loc"],
                                                        style:
                                                            const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                                                    Text("M ${eewData["eq"]["mag"]}",
                                                        style:
                                                            const TextStyle(fontSize: 26, fontWeight: FontWeight.w600))
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("$eewTime 發生",
                                                        style:
                                                            const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                                                    Text("${eewData["eq"]["depth"]}km",
                                                        style:
                                                            const TextStyle(fontSize: 16, fontWeight: FontWeight.w400))
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 55,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: context.colors.intensity(eewData["eq"]["max"]),
                                          ),
                                          child: Center(
                                            child: Text(
                                              intensityToNumberString(eewData["eq"]["max"]),
                                              style: TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onIntensity(eewData["eq"]["max"]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 5),
                Container(
                  child: (eewID != "" || city == "" || town == "")
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: double.infinity),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: (city == "" || town == "")
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: double.infinity),
                                          Text("請在設定頁面中 設定所在地",
                                              style: TextStyle(
                                                  color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("所在地預估",
                                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                                              Text("$city$town",
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300))
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 75,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12.0),
                                                  color: context.colors.intensity(userIntensity),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    intensityToNumberString(userIntensity),
                                                    style: TextStyle(
                                                      fontSize: 55,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onIntensity(userIntensity),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Text("⚠️ P波",
                                                              style:
                                                                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center, // 设置为居中
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                ((pArrive <
                                                                        (timeNtp +
                                                                            (DateTime.now().millisecondsSinceEpoch -
                                                                                timeLocal)))
                                                                    ? "抵達"
                                                                    : ((pArrive -
                                                                                (timeNtp +
                                                                                    (DateTime.now()
                                                                                            .millisecondsSinceEpoch -
                                                                                        timeLocal))) /
                                                                            1000)
                                                                        .toStringAsFixed(0)),
                                                                style: const TextStyle(
                                                                    fontSize: 38, fontWeight: FontWeight.w900),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Text("🚨 S波",
                                                              style:
                                                                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center, // 设置为居中
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                ((sArrive <
                                                                        (timeNtp +
                                                                            (DateTime.now().millisecondsSinceEpoch -
                                                                                timeLocal)))
                                                                    ? "抵達"
                                                                    : ((sArrive -
                                                                                (timeNtp +
                                                                                    (DateTime.now()
                                                                                            .millisecondsSinceEpoch -
                                                                                        timeLocal))) /
                                                                            1000)
                                                                        .toStringAsFixed(0)),
                                                                style: const TextStyle(
                                                                    fontSize: 38, fontWeight: FontWeight.w900),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("強震監視器"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
              ),
              tooltip: "幫助",
              color: context.colors.onSurfaceVariant,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutRts()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Text(
                  "即時資料僅供參考\n實際請以中央氣象署的資料為主",
                  textAlign: TextAlign.center,
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: stack != null
                      ? ClipRRect(
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            maxScale: 10,
                            child: stack!,
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
                Container(
                  child: (eewID != "")
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: (eewData["eq"]["max"] > 4) ? Colors.red : Colors.orange,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: double.infinity),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text((eewData["eq"]["max"] > 4) ? "緊急地震速報" : "地震速報",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                                        Text("#${eewData["serial"]}",
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300))
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(eewData["eq"]["loc"],
                                                        style:
                                                            const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                                                    Text("M ${eewData["eq"]["mag"]}",
                                                        style:
                                                            const TextStyle(fontSize: 26, fontWeight: FontWeight.w600))
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("$eewTime 發生",
                                                        style:
                                                            const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                                                    Text("${eewData["eq"]["depth"]}km",
                                                        style:
                                                            const TextStyle(fontSize: 16, fontWeight: FontWeight.w400))
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 55,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: context.colors.intensity(eewData["eq"]["max"]),
                                          ),
                                          child: Center(
                                            child: Text(
                                              intensityToNumberString(eewData["eq"]["max"]),
                                              style: TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onIntensity(eewData["eq"]["max"]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 5),
                Container(
                  child: (eewID != "" || city == "" || town == "")
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.blue,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: double.infinity),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: (city == "" || town == "")
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: double.infinity),
                                          Text("請在設定頁面中 設定所在地",
                                              style: TextStyle(
                                                  color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("所在地預估",
                                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                                              Text("$city$town",
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300))
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 75,
                                                height: 75,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12.0),
                                                  color: context.colors.intensity(userIntensity),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    intensityToNumberString(userIntensity),
                                                    style: TextStyle(
                                                      fontSize: 55,
                                                      fontWeight: FontWeight.bold,
                                                      color: context.colors.onIntensity(userIntensity),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Text("⚠️ P波",
                                                              style:
                                                                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center, // 设置为居中
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                ((pArrive <
                                                                        (timeNtp +
                                                                            (DateTime.now().millisecondsSinceEpoch -
                                                                                timeLocal)))
                                                                    ? "抵達"
                                                                    : ((pArrive -
                                                                                (timeNtp +
                                                                                    (DateTime.now()
                                                                                            .millisecondsSinceEpoch -
                                                                                        timeLocal))) /
                                                                            1000)
                                                                        .toStringAsFixed(0)),
                                                                style: const TextStyle(
                                                                    fontSize: 38, fontWeight: FontWeight.w900),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const Text("🚨 S波",
                                                              style:
                                                                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center, // 设置为居中
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                ((sArrive <
                                                                        (timeNtp +
                                                                            (DateTime.now().millisecondsSinceEpoch -
                                                                                timeLocal)))
                                                                    ? "抵達"
                                                                    : ((sArrive -
                                                                                (timeNtp +
                                                                                    (DateTime.now()
                                                                                            .millisecondsSinceEpoch -
                                                                                        timeLocal))) /
                                                                            1000)
                                                                        .toStringAsFixed(0)),
                                                                style: const TextStyle(
                                                                    fontSize: 38, fontWeight: FontWeight.w900),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                              )
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
