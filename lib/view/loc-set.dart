import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../main.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  final List<Widget> _List_children = <Widget>[const SizedBox(height: 10)];
  bool init = false;

  void subscribeToTopic(String newTopic, String currentTopic) async {
    String encode_newTopic = safeBase64Encode(newTopic);
    String encode_currentTopic = safeBase64Encode(currentTopic);
    print(
        "unsubscribe $currentTopic >> $encode_currentTopic | subscribe $newTopic $encode_newTopic");
    await messaging.unsubscribeFromTopic(encode_currentTopic);
    await messaging.subscribeToTopic(encode_newTopic);
  }

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
            color: const Color(0xff333439),
            margin: const EdgeInsets.all(5),
            child: ListTile(
              onTap: () async {
                if (data["storage"] == "loc-city") {
                  String town =
                      data["loc_data"][data["data"][i]].keys.toList()[0];
                  subscribeToTopic(
                      data["data"][i], prefs.getString('loc-city') ?? "臺南市");
                  subscribeToTopic(data["data"][i] + town,
                      "${prefs.getString('loc-city') ?? "臺南市"}${prefs.getString('loc-town') ?? "歸仁區"}");
                  prefs.setString("loc-town", town);
                } else if (data["storage"] == "loc-town") {
                  subscribeToTopic(data["data"][i] + data["data"][i],
                      "${prefs.getString('loc-city') ?? "臺南市"}${prefs.getString('loc-town') ?? "歸仁區"}");
                }
                prefs.setString(data["storage"], data["data"][i]);
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
