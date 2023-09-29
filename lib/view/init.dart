import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'history.dart';
import 'home.dart';
import 'me.dart';

bool init = false;

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  _InitPage createState() => _InitPage();
}

class _InitPage extends State<InitPage> {
  int _currentIndex = 0;
  final pages = [const HomePage(), const HistoryPage(), const MePage()];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (init) return;
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      var data = await get("https://api.exptech.com.tw/api/v1/dpip/info");
      if (data != false) {
        init = true;
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
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首頁'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined), label: '歷史'),
          BottomNavigationBarItem(
              icon: Icon(Icons.supervised_user_circle_outlined), label: '我的'),
        ],
        currentIndex: _currentIndex,
        fixedColor: Colors.blue[800],
        onTap: _onItemClick,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _onItemClick(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
