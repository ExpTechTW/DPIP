import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils.dart';

var data;

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPage createState() => _HistoryPage();
}

class _HistoryPage extends State<HistoryPage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];

  @override
  void initState() {
    render();
    super.initState();
  }

  @override
  void dispose() {
    data = null;
    super.dispose();
  }

  void render() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    data ??= await get(
        "https://api.exptech.com.tw/api/v1/dpip/history?city=${prefs.getString('loc-city') ?? "臺南市"}&town=${prefs.getString('loc-town') ?? "歸仁區"}");
    _List_children = <Widget>[];
    if (data == null || data == false) {
      _List_children.add(const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "服務異常",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w100, color: Colors.red),
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
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    prefs.getString("loc-city") ?? "臺南市",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    prefs.getString("loc-town") ?? "歸仁區",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.grey),
                  ),
                ],
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
                  "過去 72小時 暫無防災資訊",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ),
          ));
        } else {
          for (var i = 0; i < data["loc"].length; i++) {
            DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(data["loc"][i]["time"], isUtc: true).add(const Duration(hours: 8));
            String formattedDate =
                '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
            _List_children.add(Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  Row(
                    children: [
                      Icon(
                        (data["loc"][i]["type"] == 2)
                            ? Icons.warning_amber_outlined
                            : (data["loc"][i]["type"] == 1)
                                ? Icons.doorbell_outlined
                                : Icons.speaker_notes_outlined,
                        color: (data["loc"][i]["type"] == 2)
                            ? Colors.red
                            : (data["loc"][i]["type"] == 1)
                                ? Colors.amber
                                : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data["loc"][i]["title"],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    data["loc"][i]["body"],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          }
        }
      } else {
        _List_children.add(const Padding(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "全國",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              )
            ],
          ),
        ));
        if (data["all"].length == 0) {
          _List_children.add(const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: double.infinity),
                Text(
                  "過去 72小時 暫無防災資訊",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ),
          ));
        } else {
          for (var i = 0; i < data["all"].length; i++) {
            DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(data["all"][i]["time"], isUtc: true).add(const Duration(hours: 8));
            String formattedDate =
                '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
            _List_children.add(Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  Row(
                    children: [
                      Icon(
                        (data["all"][i]["type"] == 2)
                            ? Icons.warning_amber_outlined
                            : (data["all"][i]["type"] == 1)
                                ? Icons.doorbell_outlined
                                : Icons.speaker_notes_outlined,
                        color: (data["all"][i]["type"] == 2)
                            ? Colors.red
                            : (data["all"][i]["type"] == 1)
                                ? Colors.amber
                                : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data["all"][i]["title"],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                      backgroundColor: (_page == 1) ? Colors.blue[800] : Colors.transparent,
                      elevation: 20,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      _page = 1;
                      render();
                    },
                    child: const Text(
                      "全國",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_page == 0) ? Colors.blue[800] : Colors.transparent,
                      elevation: 20,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      _page = 0;
                      render();
                    },
                    child: const Text(
                      "所在地",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(physics: const ClampingScrollPhysics(), children: _List_children.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
