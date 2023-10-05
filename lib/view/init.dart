import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dpip/core/api.dart';
import 'package:dpip/view/earthquake.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import 'history.dart';
import 'home.dart';
import 'me.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  _InitPage createState() => _InitPage();
}

class _InitPage extends State<InitPage> {
  int _currentIndex = 0;
  var pages = [
    HomePage(),
    const HistoryPage(),
    const EarthquakePage(),
    const MePage(), //TODO 更多
    const MePage()
  ];

  bool loaded = false;

  @override
  void initState() {
    render();
    super.initState();
  }

  void render() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.grey[850],
            title: Row(
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  color: Colors.orangeAccent,
                ),
                SizedBox(width: 10),
                Text(
                  '無網路連接',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ),
            content: Text(
              '您的設備目前沒有網路連接。請檢查您的網絡設置，然後重試。',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitPage(), // 這裡是當前頁面的類型
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  '重試',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String token = await messaging.getToken() ?? "";
    print(token);
    var data = await get(
        "https://api.exptech.com.tw/api/v1/dpip/info?token=$token&city=${prefs.getString('loc-city') ?? "臺南市"}&town=${prefs.getString('loc-town') ?? "歸仁區"}");
    if (data != false) {
      if (compareVersion(data["ver"], packageInfo.version) == 1) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              backgroundColor: Colors.grey[850],
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    '發現新版本!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: Container(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    data["note"],
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    '知道了',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.grey[850],
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Text(
                  '伺服器異常',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
            content: Text(
              '無法連接到伺服器。伺服器可能正在經歷大量請求，或發生異常。目前正在全力維修中，請稍後重試。',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitPage(), // 這裡是當前頁面的類型
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  '重試',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
    loaded = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: '首頁'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined), label: '歷史'),
            BottomNavigationBarItem(
                icon: Icon(Icons.heart_broken_outlined), label: '地震'),
            BottomNavigationBarItem(
                icon: Icon(Icons.playlist_add_outlined), label: '更多'),
            BottomNavigationBarItem(
                icon: Icon(Icons.supervised_user_circle_outlined), label: '我的'),
          ],
          currentIndex: _currentIndex,
          fixedColor: Colors.blue[800],
          onTap: (!loaded) ? null : _onItemClick,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  void _onItemClick(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
