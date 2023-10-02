import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  final List<Widget> _List_children = <Widget>[const SizedBox(height: 10)];
  bool init = false;

  @override
  Widget build(BuildContext context) {
    dynamic data = ModalRoute.of(context)!.settings.arguments;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (init) return;
      init = true;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (var i = 0; i < data["data"].length; i++) {
        _List_children.add(
          Card(
            color: const Color(0xff333439), // 更改卡片顏色
            margin: const EdgeInsets.all(5), // 增加一些外邊距
            child: ListTile(
              onTap: () {
                prefs.setString(data["storage"], data["data"][i]);
                if (data["storage"] == "loc-city") {
                  prefs.setString("loc-town",
                      data["loc_data"][data["data"][i]].keys.toList()[0]);
                }
                Navigator.pop(context, 'refresh');
              },
              title: Text(
                data["data"][i],
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 30),
            ),
          ),
        );
      }
      if (mounted) setState(() {});
    });
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
