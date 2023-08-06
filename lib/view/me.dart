import 'package:dpip/core/api.dart';
import 'package:dpip/view/setting.dart';
import 'package:dpip/view/version.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'about.dart';

bool init = false;

class MePage extends StatefulWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  _MePage createState() => _MePage();
}

class _MePage extends State<MePage> {
  List<Widget> _List_children = <Widget>[];
  var loc_data;

  @override
  void dispose() {
    init = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!init) {
        loc_data = await get(
            "https://cdn.jsdelivr.net/gh/ExpTechTW/TREM-Lite@Release/src/resource/data/region.json");
      }
      init = true;
      _List_children = <Widget>[];
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _List_children.add(GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingPage(),
                settings: RouteSettings(
                  arguments: {
                    "data": loc_data.keys.toList(),
                    "storage": "loc-city"
                  },
                ),
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "所在地(縣市)",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    "設定所在地縣市",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  prefs.getString("loc-city") ?? "未設定",
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.end,
                ),
              ),
              const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.white, size: 20)),
            ],
          ),
        ),
      ));
      _List_children.add(const Divider(color: Colors.grey, thickness: 0.5));
      _List_children.add(GestureDetector(
        onTap: () {
          if (prefs.getString("loc-city") != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingPage(),
                  settings: RouteSettings(
                    arguments: {
                      "data":
                          loc_data[prefs.getString("loc-city")].keys.toList(),
                      "storage": "loc-town"
                    },
                  ),
                ));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "所在地(鄉鎮市區)",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    "設定所在地鄉鎮市區",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  prefs.getString("loc-town") ?? "未設定",
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.end,
                ),
              ),
              const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.white, size: 20)),
            ],
          ),
        ),
      ));
      _List_children.add(const Divider(color: Colors.grey, thickness: 0.5));
      _List_children.add(GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VersionPage(),
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "版本",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  "${packageInfo.version} | ${(!packageInfo.version.endsWith("0")) ? "預覽版" : "穩定版"}",
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.end,
                ),
              ),
              const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.white, size: 20)),
            ],
          ),
        ),
      ));
      _List_children.add(const Divider(color: Colors.grey, thickness: 0.5));
      _List_children.add(GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutPage(),
              ));
        },
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "關於",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
              Expanded(
                child: SizedBox(),
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Icon(Icons.arrow_forward_ios_outlined,
                      color: Colors.white, size: 20)),
            ],
          ),
        ),
      ));
      _List_children.add(const Divider(color: Colors.grey, thickness: 0.5));
      if (!mounted) return;
      setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: _List_children.toList(),
        ),
      ),
    );
  }
}
