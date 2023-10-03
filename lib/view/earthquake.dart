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

class _EarthquakePage extends State<EarthquakePage> {
  String url = 'https://exptech.com.tw/api/v1/trem/rts-image';
  late Widget _pic = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  late final Widget _taiwan = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  late final Widget _int = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  int replay = 0;
  late Timer clock, reports_clock;

  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  String reports_url =
      "https://yayacat.exptech.com.tw/api/v3/earthquake/reports";

  @override
  void initState() {
    _updateImgWidget();
    clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateImgWidget();
      if (mounted) {
        setState(() {});
      }
    });
    reports_clock = Timer.periodic(const Duration(seconds: 600), (timer) async {
      await _updateReportsWidget();
      if (mounted) {
        setState(() {});
      }
    });
    _updateReportsWidget();
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

  _updateReportsWidget() async {
    try {
      data ??= await post(reports_url, {"list": {}});
    } on TimeoutException catch (e) {
      return;
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _List_children = <Widget>[];
      if (_taiwan == null || _pic == null || _int == null || data == null) {
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
            padding: const EdgeInsets.all(15),
            child: Stack(
                alignment: Alignment.center, // 对齐到中心
                children: [
                  _taiwan,
                  _pic,
                  _int,
                ]),
          ));
        } else {
          print(data);
          if (data is! bool) {
            for (var i = 0; i < data.length; i++) {
              _List_children.add(Padding(
                padding: EdgeInsets.all(5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff333439),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          data[i]["data"][0]["areaIntensity"].toString(),
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data[i]["location"]
                                      .substring(
                                          data[i]["location"].indexOf("(") + 1,
                                          data[i]["location"].indexOf(")"))
                                      .replaceAll("位於", ""),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w100,
                                      color: Colors.white),
                                ),
                                Text(
                                  data[i]["originTime"],
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w100,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "M " +
                                    data[i]["magnitudeValue"]
                                        .toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              // Text(
                              //   ".${data["info"]["temp"].split(".")[1]}°C",
                              //   style: const TextStyle(
                              //     fontSize: 30,
                              //     fontWeight: FontWeight.w300,
                              //     color: Colors.white,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
            }
          }
        }
      }
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              if (_page == 0) {
                _page = 1;
                setState(() {});
              }
            } else if (details.primaryVelocity! < 0) {
              if (_page == 1) {
                _page = 0;
                setState(() {});
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
                      backgroundColor:
                          (_page == 1) ? Colors.blue[800] : Colors.transparent,
                      elevation: 20,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      setState(() {
                        _page = 1;
                      });
                    },
                    child: const Text(
                      "地震報告",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_page == 0) ? Colors.blue[800] : Colors.transparent,
                      elevation: 20,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      setState(() {
                        _page = 0;
                      });
                    },
                    child: const Text(
                      "即時測站",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                    physics: const ClampingScrollPhysics(),
                    children: _List_children.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
