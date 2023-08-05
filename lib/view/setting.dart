import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  List<Widget> _List_children = <Widget>[];

  @override
  void dispose() {
    init = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dynamic data = ModalRoute.of(context)!.settings.arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (init) return;
      init = true;
      print(data["data"]);
      for (var i = 0; i < data["data"].length; i++) {
        _List_children.add(GestureDetector(
          onTap: () {
            prefs.setString(data["storage"], data["data"][i]);
            if (data["storage"] == "loc-city") prefs.remove("loc-town");
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  data["data"][i],
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ));
        _List_children.add(const Divider(
          color: Colors.grey,
          thickness: 0.5,
        ));
      }
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
