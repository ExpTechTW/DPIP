import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
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
            "https://exptech.com.tw/api/v1/dpip/alert?code=${prefs.getString('setting-loc') ?? 0}");
        if (data != false) init = true;
        print(data);
      }
      _List_children = <Widget>[];
      if (data == false) {
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
          if (prefs.getString('setting-loc') == null) {
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
            _List_children.add(Container(
              // color: Colors.red,
              height: 300,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      "2023年08月04日 10:00",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      "臺南市 歸仁區",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    Text(
                      "32°C",
                      style: TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "雨",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )
                  ],
                ),
              ),
            ));
            _List_children.add(const Padding(
              padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "臺南市 歸仁區",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w100,
                        color: Colors.white),
                  )
                ],
              ),
            ));
          }
        } else {
          _List_children.add(Image.network(
              "https://www.cwb.gov.tw/Data/satellite/TWI_VIS_TRGB_1375/TWI_VIS_TRGB_1375-2023-08-05-01-00.jpg"));
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
      setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_page == 1)
                        ? Colors.deepPurpleAccent
                        : Colors.transparent,
                    elevation: 20,
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
                const SizedBox(width: 5),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_page == 0)
                        ? Colors.deepPurpleAccent
                        : Colors.transparent,
                    elevation: 20,
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
    );
  }
}
