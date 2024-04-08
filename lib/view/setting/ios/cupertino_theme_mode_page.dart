import 'package:flutter/cupertino.dart';

class CupertinoThemeModePage extends StatefulWidget {
  final String themeMode;

  const CupertinoThemeModePage({super.key, required this.themeMode});

  @override
  State<CupertinoThemeModePage> createState() => _CupertinoThemeModePageState();
}

class _CupertinoThemeModePageState extends State<CupertinoThemeModePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("主題模式"),
      ),
      child: ListView(
        children: [
          CupertinoListSection.insetGrouped(
            children: [
              CupertinoListTile(
                title: const Text("淺色"),
                additionalInfo: Visibility(
                  visible: widget.themeMode == "light",
                  child: const Icon(CupertinoIcons.check_mark),
                ),
                onTap: () {
                  Navigator.pop(context, "light");
                },
              ),
              CupertinoListTile(
                title: const Text("深色"),
                additionalInfo: Visibility(
                  visible: widget.themeMode == "dark",
                  child: const Icon(CupertinoIcons.check_mark),
                ),
                onTap: () {
                  Navigator.pop(context, "dark");
                },
              ),
              CupertinoListTile(
                title: const Text("跟隨系統主題"),
                additionalInfo: Visibility(
                  visible: widget.themeMode == "system",
                  child: const Icon(CupertinoIcons.check_mark),
                ),
                onTap: () {
                  Navigator.pop(context, "system");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
