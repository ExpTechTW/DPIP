import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPage createState() => _SettingPage();
}

class _SettingPage extends State<SettingPage> {
  List<Widget> _List_children = <Widget>[];

  @override
  Widget build(BuildContext context) {
    dynamic data = ModalRoute.of(context)!.settings.arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print(data["data"]);
      _List_children = <Widget>[];
      for (var i = 0; i < data["data"].length; i++) {
        print(data["data"][i]);
        _List_children.add(GestureDetector(
          onTap: () {
            print('Row is tapped!');
          },
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  data["data"][i].toString(),
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
