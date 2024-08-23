import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/history/history.dart';
import 'package:dpip/app/page/home/home.dart';
import 'package:dpip/app/page/map/map.dart';
import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/more/more.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/changelog/changelog.dart';
import 'package:dpip/route/update_required/update_required.dart';
import 'package:dpip/route/welcome/about.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Dpip extends StatefulWidget {
  const Dpip({Key? key}) : super(key: key);

  @override
  State<Dpip> createState() => _DpipState();
}

class _DpipState extends State<Dpip> {
  PageController controller = PageController();
  int currentActivePage = 0;
  bool update = false;
  bool criticalUpdate = false;
  String lastVersion = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates();
    });
  }

  Future<void> checkForUpdates() async {
    try {
      var data = await ExpTech().getSupport();
      List<String> criticalList = (data["support-version"] as List<dynamic>).cast<String>();

      if (Global.packageInfo.version.endsWith(".0")) {
        lastVersion = data["last-version"]["release"];
        update = (Global.packageInfo.version != lastVersion);
      } else {
        lastVersion = data["last-version"]["beta"];
        update = (Global.packageInfo.version != lastVersion);
      }

      criticalUpdate = !criticalList.contains(Global.packageInfo.version);

      bool skip =
          (DateTime.now().millisecondsSinceEpoch - (Global.preference.getInt("update-skip") ?? 0)) < 86400 * 3 * 1000;

      if ((update && !skip) || criticalUpdate) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => UpdateRequiredPage(
                      showSkipButton: !criticalUpdate,
                      lastVersion: lastVersion,
                    )),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (Global.preference.getBool("welcome-1.0.0") == null) {
          Global.preference.setBool("welcome-1.0.0", true);
          Global.preference.setString("changelog", Global.packageInfo.version);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutPage()),
            );
          }
        } else {
          if (Global.preference.getString("changelog") != Global.packageInfo.version) {
            Global.preference.setString("changelog", Global.packageInfo.version);
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  icon: const Icon(Symbols.update_rounded),
                  title: const Text("更新完成"),
                  content: const Text(
                    "DPIP 更新完成，要前往查看更新日誌嗎？",
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton(
                      child: const Text("稍後再說"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text("前往查看"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangelogPage()),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      print("Error checking for updates: $e");
      update = false;
      criticalUpdate = false;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentActivePage,
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.home),
            selectedIcon: const Icon(Symbols.home, fill: 1),
            label: context.i18n.home,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.clock_loader_10_rounded),
            selectedIcon: const Icon(Symbols.clock_loader_10_rounded, fill: 1),
            label: context.i18n.history,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.map),
            selectedIcon: const Icon(Symbols.map, fill: 1),
            label: context.i18n.map,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.note_stack_add_rounded),
            selectedIcon: const Icon(Symbols.note_stack_add_rounded, fill: 1),
            label: "更多",
          ),
          NavigationDestination(
            icon: const Icon(Symbols.person),
            selectedIcon: const Icon(Symbols.person, fill: 1),
            label: context.i18n.me,
          ),
        ],
        onDestinationSelected: (value) {
          setState(() {
            currentActivePage = value;
          });
          controller.jumpToPage(currentActivePage);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomePage(),
          HistoryPage(),
          MapPage(),
          MorePage(),
          MePage(),
        ],
      ),
    );
  }
}
