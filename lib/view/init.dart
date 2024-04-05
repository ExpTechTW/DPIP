import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dpip/core/utils.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/view/earthquake.dart';
import 'package:dpip/view/report_list.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'me.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  int _currentIndex = 0;
  var pages = [
    // const HomePage(),
    // const HistoryPage(),
    const EarthquakePage(),
    const ReportList(),
    // const Radar(), //TODO 更多
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
            icon: const Icon(
              Icons.wifi_off_outlined,
              color: Colors.orangeAccent,
            ),
            title: const Text(
              '無網路連接',
              style: TextStyle(color: Colors.orangeAccent),
            ),
            content: const Text(
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
    var data = await get("https://api.exptech.com.tw/api/v1/dpip/info");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await messaging.subscribeToTopic(
        safeBase64Encode(prefs.getString('loc-city') ?? "臺南市"));
    await messaging.subscribeToTopic(safeBase64Encode(
        "${prefs.getString('loc-city') ?? "臺南市"}${prefs.getString('loc-town') ?? "歸仁區"}"));

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
    }
    /*
     else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: context.colors.error,
            ),
            title: Text(
              '無法連接到伺服器',
              style: TextStyle(color: context.colors.error),
            ),
            content: const Text(
              '伺服器可能正在經歷大量請求，或發生異常。目前正在全力維修中，請稍後重試。',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '知道了',
                ),
              ),
            ],
          );
        },
      );
    }
    */

    loaded = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.home_outlined), label: '首頁'),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.history_outlined), label: '歷史'),
          NavigationDestination(
            icon: Icon(Icons.heart_broken_outlined),
            selectedIcon: Icon(Icons.heart_broken),
            label: '監視器',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: '地震報告',
          ),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.playlist_add_outlined), label: '更多'),
          NavigationDestination(
            icon: Icon(Icons.supervised_user_circle_outlined),
            selectedIcon: Icon(Icons.supervised_user_circle),
            label: '我',
          ),
        ],
      ),
    );
  }
}
