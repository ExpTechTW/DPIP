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
        var data = get(
            "https://exptech.com.tw/api/v1/dpip/alert?code=${prefs.getString('setting-location') ?? 0}");
        print(data);
      }
      init = true;
      _List_children = <Widget>[];
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
      _List_children.add(const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity),
            Text(
              "地震資訊(測試)",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              "2023年08月04日 09:48 發布",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              "臺灣東部海域 最大震度 5弱\n本地震度 2級",
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          ],
        ),
      ));
      _List_children.add(const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity),
            Text(
              "停班停課(測試)",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              "2023年08月04日 08:48 發布",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              "受 今年 第6號 颱風 影響\n臺南市 4日 停止上班上課",
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          ],
        ),
      ));
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
                    _page = 1;
                    init = false;
                    setState(() {});
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
                    _page = 0;
                    init = false;
                    setState(() {});
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
