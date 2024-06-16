import 'package:flutter/material.dart';

import '../home_page.dart';
import '../init.dart';

class WelcomeNotifyPage extends StatefulWidget {
  const WelcomeNotifyPage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _WelcomeNotifyPageState();
}

class _WelcomeNotifyPageState extends State<WelcomeNotifyPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: Text("通知")),
            body: Padding(
                padding: EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("內文"),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => InitPage()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: Text("下一步")))
                ]))));
  }
}
