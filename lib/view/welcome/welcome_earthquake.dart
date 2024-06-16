import 'package:dpip/view/welcome/welcome_notify.dart';
import 'package:flutter/material.dart';

import '../../global.dart';

class WelcomeEarthquakePage extends StatefulWidget {
  const WelcomeEarthquakePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _WelcomeEarthquakePageState();
}

class _WelcomeEarthquakePageState extends State<WelcomeEarthquakePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: const Text("強震監視器")),
            body: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("內文"),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF009E8B), Color(0xFF203864)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              await Global.preference.setBool("monitor", true);
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => const WelcomeNotifyPage()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                            ),
                            child: const Text(
                              "同意",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF009E8B), Color(0xFF203864)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              await Global.preference.setBool("monitor", false);
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => const WelcomeNotifyPage()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                            ),
                            child: const Text(
                              "不同意",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]))));
  }
}
