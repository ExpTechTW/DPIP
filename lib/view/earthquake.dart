import 'dart:async';
import 'dart:typed_data';

import 'package:dpip/util/extension.dart';
import 'package:dpip/view/about_rts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/utils.dart';
import 'dart:math';

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({super.key});

  @override
  State<EarthquakePage> createState() => _EarthquakePage();
}

dynamic data;

class _EarthquakePage extends State<EarthquakePage> {
  String url = 'https://lb-1.exptech.com.tw/api/v1/trem/rts-image';
  String eewUrl = "https://lb-1.exptech.com.tw/api/v1/eq/eew/";
  Widget _pic = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  final Widget _taiwan = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  final Widget _int = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  late Timer clock;
  late Timer ntpClock;
  int replay = 0;
  int timeNtp = 0;
  int timeLocal = 0;

  Widget stack = const CircularProgressIndicator();

  void ntp() async {
    var ans = await get("https://api.exptech.com.tw/ntp");
    if (ans != false) {
      timeNtp = ans - 1000;
      timeLocal = DateTime.now().millisecondsSinceEpoch;
    }
  }

  int randomNum(int max) {
    return Random().nextInt(max) + 1;
  }

  Future<void> updateImage() async {
    try {
      if (replay != 0) replay += 1000;

      Uint8List bytes = await http
          .readBytes(Uri.parse(url +
              ((replay != 0)
                  ? "/${DateTime.fromMillisecondsSinceEpoch(replay).millisecondsSinceEpoch}"
                  : "?time=${DateTime.now().millisecondsSinceEpoch}")))
          .timeout(const Duration(seconds: 1));

      _pic = Image.memory(bytes, gaplessPlayback: true);

      data ??= await get(
          "https://lb-${randomNum(4)}.exptech.com.tw/api/v2/eq/report?limit=50");

      setState(() {
        stack = Stack(
          alignment: Alignment.center,
          children: [
            _taiwan,
            _pic,
            _int,
          ],
        );
      });
    } catch (e) {
      return;
    }
  }

  @override
  void initState() {
    ntp();
    ntpClock = Timer.periodic(const Duration(seconds: 60), (timer) {
      ntp();
    });

    clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
      updateImage();
    });

    super.initState();
  }

  @override
  void dispose() {
    clock.cancel();
    ntpClock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("強震監視器"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
            ),
            color: context.colors.onSurfaceVariant,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutRts()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Text(
                "即時資料僅供參考\n實際請以中央氣象署的資料為主",
                textAlign: TextAlign.center,
              ),
              Flexible(
                flex: 1,
                child: Center(child: stack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
