import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as HTTP;

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({Key? key}) : super(key: key);

  @override
  _EarthquakePage createState() => _EarthquakePage();
}

class _EarthquakePage extends State<EarthquakePage> {
  String url = 'https://exptech.com.tw/api/v1/trem/rts-image';
  late Widget _pic = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/rts.png");
  late final Widget _taiwan = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/taiwan.png");
  late final Widget _int = Image.network(
      "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/int.png");
  int replay = 0;
  late Timer clock;

  @override
  void initState() {
    _updateImgWidget();
    clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateImgWidget();
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  _updateImgWidget() async {
    try {
      if (replay != 0) replay += 1000;
      Uint8List bytes = await HTTP
          .readBytes(Uri.parse(url + ((replay != 0) ? "?time=$replay" : "")))
          .timeout(const Duration(seconds: 5)); // 设置5秒的超时时间
      _pic = Image.memory(bytes, gaplessPlayback: true);
    } on TimeoutException catch (e) {
      return;
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                  alignment: Alignment.center, // 对齐到中心
                  children: [
                    _taiwan,
                    _pic,
                    _int,
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
