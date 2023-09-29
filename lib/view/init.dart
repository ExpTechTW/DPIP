import 'package:flutter/material.dart';

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
  final pages = [HomePage(), HistoryPage(), MePage()];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (init) return;
      init = true;
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
              height: 200, // 你可以根据需要设置一个固定高度
              child: SingleChildScrollView(
                child: Text(
                  '',
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
