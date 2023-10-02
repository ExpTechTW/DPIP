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
        _List_children.add(Container(
          color: Colors.white10,
          child: InkWell(
            onTap: () {
              prefs.setString(data["storage"], data["data"][i]);
              if (data["storage"] == "loc-city") {
                prefs.setString("loc-town",
                    data["loc_data"][data["data"][i]].keys.toList()[0]);
              }
              Navigator.pop(context, 'refresh');
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["data"][i],
                        style:
                            const TextStyle(fontSize: 22, color: Colors.white),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  const Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.arrow_right,
                          color: Colors.white, size: 30)),
                ],
              ),
            ),
          ),
        ));
        _List_children.add(const SizedBox(height: 10));
      }
      if (mounted) setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          children: _List_children.toList(),
        ),
      ),
    );
  }
}
