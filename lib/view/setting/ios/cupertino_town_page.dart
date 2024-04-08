import 'package:dpip/global.dart';
import 'package:flutter/cupertino.dart';

class CupertinoTownPage extends StatefulWidget {
  final String city;
  final String town;

  const CupertinoTownPage({super.key, required this.city, required this.town});

  @override
  State<CupertinoTownPage> createState() => _CupertinoTownPageState();
}

class _CupertinoTownPageState extends State<CupertinoTownPage> {
  @override
  Widget build(BuildContext context) {
    List<String> townList = Global.region[widget.city]!.keys.toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("鄉鎮市區"),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: townList.map((e) {
                if (e != widget.town) {
                  return CupertinoListTile(
                    title: Text(e),
                  );
                } else {
                  return CupertinoListTile(
                    title: Text(e),
                    trailing: const Icon(CupertinoIcons.check_mark),
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
