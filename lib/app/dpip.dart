import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/history/history.dart';
import 'package:dpip/app/page/home/home.dart';
import 'package:dpip/app/page/map/map.dart';
import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/more/more.dart';
import 'package:dpip/core/fcm.dart';
import 'package:dpip/core/notify.dart';
import 'package:dpip/core/service.dart';
import 'package:dpip/dialog/welcome/announcement.dart';
import 'package:dpip/dialog/welcome/changelog.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/update_required/update_required.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:material_symbols_icons/symbols.dart';

class Dpip extends StatefulWidget {
  const Dpip({super.key});

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
    _initializeServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates();
    });
    if (Platform.isAndroid) {
      InAppUpdate.checkForUpdate().then((info) {
        setState(() {
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            if (info.immediateUpdateAllowed) {
              InAppUpdate.performImmediateUpdate();
            } else if (info.flexibleUpdateAllowed) {
              InAppUpdate.startFlexibleUpdate().then((updateResult) {
                if (updateResult == AppUpdateResult.success) {
                  InAppUpdate.completeFlexibleUpdate();
                }
              });
            }
          }
        });
      }).catchError((e) {});
    }

    if (Global.preference.getString("changelog") != Global.packageInfo.version) {
      showDialog(context: context, builder: (context) => const WelcomeChangelogDialog());
    }
    if (false) {
      showDialog(context: context, builder: (context) => const WelcomeAnnouncementDialog());
    }
  }

  int compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split(".").map(int.parse).toList();
    List<int> v2Parts = version2.split(".").map(int.parse).toList();

    int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    v1Parts.length = maxLength;
    v2Parts.length = maxLength;
    v1Parts.fillRange(v1Parts.length, maxLength, 0);
    v2Parts.fillRange(v2Parts.length, maxLength, 0);

    for (int i = 0; i < maxLength; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        return 1;
      } else if (v1Parts[i] < v2Parts[i]) {
        return -1;
      }
    }

    return 0;
  }

  Future<void> checkForUpdates() async {
    try {
      var data = await ExpTech().getSupport();
      List<String> criticalList = (data["support-version"] as List<dynamic>).cast<String>();

      if (Global.packageInfo.version.endsWith(".0")) {
        lastVersion = data["last-version"]["release"];
      } else if (Global.packageInfo.version.endsWith("00")) {
        lastVersion = data["last-version"]["beta"];
      } else {
        lastVersion = data["last-version"]["alpha"];
      }
      update = compareVersions(lastVersion, Global.packageInfo.version) == 1 ? true : false;

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
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error checking for updates: $e");
      await _showErrorDialog();
    }
  }

  Future<void> _showErrorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            icon: const Icon(Symbols.signal_disconnected_rounded),
            title: Text("異常"),
            content: Text("網路連線或伺服器異常。"),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                child: Text("重試"),
                onPressed: () {
                  Navigator.pop(context);
                  _restartApp();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _restartApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Dpip()),
      (Route<dynamic> route) => false,
    );
  }

  void _initializeServices() {
    fcmInit();
    notifyInit();
    initBackgroundService();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
              label: context.i18n.more,
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
      ),
    );
  }
}
