import 'package:dpip/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoCityPage extends StatefulWidget {
  final String city;

  const CupertinoCityPage({super.key, required this.city});

  @override
  State<CupertinoCityPage> createState() => _CupertinoCityPageState();
}

class _CupertinoCityPageState extends State<CupertinoCityPage> {
  List<String> cityList = Global.region.keys.toList();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("縣市"),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: cityList.map((e) {
                if (e != widget.city) {
                  return CupertinoListTile(
                    title: Text(e),
                    onTap: () {
                      Navigator.pop(context, e);
                    },
                  );
                } else {
                  return CupertinoListTile(
                    title: Text(e),
                    trailing: const Icon(CupertinoIcons.check_mark),
                    onTap: () {
                      Navigator.pop(context, e);
                    },
                  );
                }
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
