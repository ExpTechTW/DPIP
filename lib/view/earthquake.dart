import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as HTTP;

import '../core/api.dart';

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
  String url = 'https://exptech.com.tw/api/v1/trem/rts-image';
  late Widget _pic = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  late final Widget _taiwan = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  late final Widget _int = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  int replay = 0;
  var clock;

  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  String reports_url =
      "https://yayacat.exptech.com.tw/api/v3/earthquake/reports";

  @override
  void initState() {
    render();
    super.initState();
  }

  _updateImgWidget() async {
    try {
      if (replay != 0) replay += 1000;
      Uint8List bytes = await HTTP
          .readBytes(Uri.parse(url + ((replay != 0) ? "?time=$replay" : "")))
          .timeout(const Duration(seconds: 5)); // 设置5秒的超时时间
      _pic = Image.memory(bytes, gaplessPlayback: true);
    } on TimeoutException catch (e) {
      return;
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    if (clock != null) clock.cancel();
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
    data ??= await post(reports_url, {"list": {}});
    _List_children = <Widget>[];
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
      if (_page == 0) {
        _List_children.add(Padding(
          padding: const EdgeInsets.all(5),
          child: Stack(alignment: Alignment.center, children: [
            _taiwan,
            _pic,
            _int,
          ]),
        ));
      } else {
        if (data is! bool) {
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
                      contentPadding:
                          const EdgeInsets.only(left: 80, right: 15),
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
                ),
              ),
            );
          }
        }
      }
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
          padding: EdgeInsets.all(5),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                if (_page == 0) {
                  _page = 1;
                  render();
                }
              } else if (details.primaryVelocity! < 0) {
                if (_page == 1) {
                  _page = 0;
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
                        "即時測站",
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
