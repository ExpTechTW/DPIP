import 'package:dpip/main.dart';
import 'package:dpip/view/map.dart';
import 'package:flutter/material.dart';

import 'history.dart';
import 'home.dart';
import 'me.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  _InitPage createState() => _InitPage();
}

//  print(await get("https://exptech.com.tw/api/v1/earthquake/reports"));
class _InitPage extends State<InitPage> {
  int _currentIndex = 0;
  final pages = [HomePage(), MyHomePage(title: ""), MePage()];

  @override
  Widget build(BuildContext context) {
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
