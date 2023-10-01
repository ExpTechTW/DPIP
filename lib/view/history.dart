import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';

bool init = false;

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPage createState() => _HistoryPage();
}

class _HistoryPage extends State<HistoryPage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  var data;

  @override
  void dispose() {
    init = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!init) {
        data = await get(
            "https://exptech.com.tw/api/v1/dpip/history?city=${prefs.getString('loc-city')}&town=${prefs.getString('loc-town')}");
        if (data != false) init = true;
        print(data);
      }
      _List_children = <Widget>[];
      if (data == null || data == false) {
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
          if (prefs.getString('loc-town') == null) {
            _List_children.add(const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "服務區域外",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w100,
                      color: Colors.white),
                ),
                Text(
                  "無法取得相關資訊 可能是因為尚未設定所在地位置",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ));
          } else {
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${prefs.getString("loc-city")} ${prefs.getString("loc-town")}",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w100,
                        color: Colors.white),
                  )
                ],
              ),
            ));
            if (data["loc"].length == 0) {
              _List_children.add(const Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      "暫無生效中的防災資訊",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ));
            } else {
              for (var i = 0; i < data["loc"].length; i++) {
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                        data["all"][i]["time"],
                        isUtc: true)
                    .add(const Duration(hours: 8));
                String formattedDate =
                    '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
                _List_children.add(Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: double.infinity),
                      Text(
                        data["all"][i]["title"],
                        style: TextStyle(
                            fontSize: 20,
                            color: (data["all"][i]["type"] == 2)
                                ? Colors.red
                                : (data["all"][i]["type"] == 1)
                                    ? Colors.amber
                                    : Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formattedDate,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        data["all"][i]["body"],
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                ));
              }
            }
          }
        } else {
          if (data["all"].length == 0) {
            _List_children.add(const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity),
                  Text(
                    "暫無生效中的防災資訊",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          } else {
            for (var i = 0; i < data["all"].length; i++) {
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                      data["all"][i]["time"],
                      isUtc: true)
                  .add(const Duration(hours: 8));
              String formattedDate =
                  '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
              _List_children.add(Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: double.infinity),
                    Text(
                      data["all"][i]["title"],
                      style: TextStyle(
                          fontSize: 20,
                          color: (data["all"][i]["type"] == 2)
                              ? Colors.red
                              : (data["all"][i]["type"] == 1)
                                  ? Colors.amber
                                  : Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      data["all"][i]["body"],
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ));
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {});
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
                      "全國",
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
                      "所在地",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: _List_children.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
