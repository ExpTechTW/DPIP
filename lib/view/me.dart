import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:dpip/view/loc-set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'about.dart';
import 'notify.dart';

var loc_data;

class MePage extends StatefulWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  _MePage createState() => _MePage();
}

class _MePage extends State<MePage> {
  List<Widget> _List_children = <Widget>[];

  @override
  void initState() {
    render();
    super.initState();
  }

  void render() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    loc_data ??= json.decode(await rootBundle.loadString('assets/region.json'));
    _List_children = <Widget>[const SizedBox(height: 10)];
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _List_children.add(const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("所在地設定",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          ListTile(
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingPage(),
                    settings: RouteSettings(
                      arguments: {
                        "data": loc_data.keys.toList(),
                        "loc_data": loc_data,
                        "storage": "loc-city"
                      },
                    ),
                  ));
              if (result != null && result == 'refresh') render();
            },
            title: const Text(
              "縣市",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prefs.getString("loc-city") ?? "臺南市",
                  style: const TextStyle(fontSize: 22, color: Colors.grey),
                  textAlign: TextAlign.end,
                ),
                const Icon(Icons.arrow_right, color: Colors.white, size: 30),
              ],
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          ListTile(
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingPage(),
                    settings: RouteSettings(
                      arguments: {
                        "data": loc_data[prefs.getString("loc-city") ?? "臺南市"]
                            .keys
                            .toList(),
                        "loc_data": loc_data,
                        "storage": "loc-town"
                      },
                    ),
                  ));
              if (result != null && result == 'refresh') render();
            },
            title: const Text(
              "鄉鎮市區",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prefs.getString("loc-town") ?? "歸仁區",
                  style: const TextStyle(fontSize: 22, color: Colors.grey),
                  textAlign: TextAlign.end,
                ),
                const Icon(Icons.arrow_right, color: Colors.white, size: 30),
              ],
            ),
          ),
        ],
      ),
    ));
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("軟體設定",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(
      Container(
        decoration: BoxDecoration(
          color: const Color(0xff333439),
          borderRadius: BorderRadius.circular(5),
        ),
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifyPage(),
                    ));
              },
              title: const Text(
                "通知",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              trailing:
                  const Icon(Icons.arrow_right, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
    _List_children.add(const SizedBox(height: 10));
    _List_children.add(const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("關於",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))
      ],
    ));
    _List_children.add(Container(
      decoration: BoxDecoration(
        color: const Color(0xff333439),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          ListTile(
            onTap: () {},
            title: const Text(
              "版本",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${packageInfo.version} ${(packageInfo.version.split(".")[2] == "0") ? "Release" : "Pre-Release"}",
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const Icon(Icons.arrow_right, color: Colors.white, size: 30),
              ],
            ),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          ListTile(
            onTap: () async {
              FlutterClipboard.copy(await messaging.getToken() ?? "");
              const snackBar = SnackBar(content: Text('已複製 FCM 令牌!'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            title: const Text(
              "令牌",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing:
                const Icon(Icons.arrow_right, color: Colors.white, size: 30),
          ),
          const Divider(
              color: Colors.grey, thickness: 0.5, indent: 20, endIndent: 20),
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ));
            },
            title: const Text(
              "關於",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            trailing:
                const Icon(Icons.arrow_right, color: Colors.white, size: 30),
          ),
        ],
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: _List_children.toList(),
          ),
        ),
      ),
    );
  }
}
