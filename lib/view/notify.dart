import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class NotifyPage extends StatelessWidget {
  const NotifyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("音效測試"),
        ),
        child: ListView(
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("音效測試"),
        ),
        body: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x660063C6),
                    Color(0xFF0063C6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(90)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 靠兩側(其實我看不太懂
                children: [
                  Text(
                    '強震即時警報 (EEW) ',
                    style: TextStyle(fontSize: 21,fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    Icons.play_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}