import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/view/earthquake.dart';
import 'package:dpip/view/report_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'me.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class UpdateChecker extends StatefulWidget {
  @override
  _UpdateCheckerState createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  String _currentVersion = '';
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });

    // Assume _getLatestVersion() fetches the latest version from your backend
    _getLatestVersion().then((latestVersion) {
      setState(() {
        _latestVersion = latestVersion;
      });

      if (_latestVersion != '' && _latestVersion != _currentVersion) {
        _showUpdateDialog();
      }
    }).catchError((error) {
      print('取得最新版本時錯誤: $error');
    });
  }

  Future<String> _getLatestVersion() async {
    // Implement logic to fetch latest version from your backend
    // This is just a placeholder, replace it with your actual implementation
    return '1.2.1';
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新版本可用'),
          content: Text('一個新版本的應用程式可用。請更新到版本 $_latestVersion。'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _launchAppStore();
              },
              child: Text('更新'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('稍後'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchAppStore() async {
    const url =
        'https://apps.apple.com/tw/app/dpip-%E7%81%BD%E5%AE%B3%E5%A4%A9%E6%B0%A3%E8%88%87%E5%9C%B0%E9%9C%87%E9%80%9F%E5%A0%B1/id6468026362';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw '無法打開App Store URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your widget build logic
    return Container(); // Placeholder, replace it with your actual UI
  }
}

class _InitPageState extends State<InitPage> {
  int currentPageIndex = 0;
  late PageController _pageController;
  List<Widget> bodyPages = [
    // const HomePage(),
    // const HistoryPage(),
    const EarthquakePage(),
    const ReportList(),
    // const Radar(), //TODO 更多
    const MePage()
  ];

  bool loaded = false;
  bool isInternetConnected = true;

  Future<void> checkForUpdate() async {
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
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: currentPageIndex);

    render();

    if (Platform.isAndroid) {
      checkForUpdate();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  void render() async {
    Connectivity().onConnectivityChanged.listen((event) {
      setState(() {
        if (event.contains(ConnectivityResult.none)) {
          isInternetConnected = false;
        } else {
          isInternetConnected = true;
        }
      });
    });

    /*
     else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: context.colors.error,
            ),
            title: Text(
              '無法連接到伺服器',
              style: TextStyle(color: context.colors.error),
            ),
            content: const Text(
              '伺服器可能正在經歷大量請求，或發生異常。目前正在全力維修中，請稍後重試。',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '知道了',
                ),
              ),
            ],
          );
        },
      );
    }
    */

    loaded = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: currentPageIndex,
          items: const <BottomNavigationBarItem>[
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.home_outlined), label: '首頁'),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.history_outlined), label: '歷史'),
            BottomNavigationBarItem(
              icon: Icon(Icons.heart_broken_outlined),
              activeIcon: Icon(Icons.heart_broken),
              label: '監視器',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: '地震報告',
            ),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.playlist_add_outlined), label: '更多'),
            BottomNavigationBarItem(
              icon: Icon(Icons.supervised_user_circle_outlined),
              activeIcon: Icon(Icons.supervised_user_circle),
              label: '我',
            ),
          ],
          onTap: (value) {
            setState(() {
              currentPageIndex = value;
              _pageController.jumpToPage(currentPageIndex);
            });
          },
        ),
        tabBuilder: (context, index) {
          return bodyPages[index];
        },
      );
    } else {
      return Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentPageIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentPageIndex = index;
              _pageController.jumpToPage(currentPageIndex);
            });
          },
          destinations: const <NavigationDestination>[
            // NavigationDestination(
            //     icon: Icon(Icons.home_outlined), label: '首頁'),
            // NavigationDestination(
            //     icon: Icon(Icons.history_outlined), label: '歷史'),
            NavigationDestination(
              icon: Icon(Icons.heart_broken_outlined),
              selectedIcon: Icon(Icons.heart_broken),
              label: '監視器',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: '地震報告',
            ),
            // NavigationDestination(
            //     icon: Icon(Icons.playlist_add_outlined), label: '更多'),
            NavigationDestination(
              icon: Icon(Icons.supervised_user_circle_outlined),
              selectedIcon: Icon(Icons.supervised_user_circle),
              label: '我',
            ),
          ],
        ),
        bottomSheet: Visibility(
          visible: !isInternetConnected,
          child: Container(
            width: double.maxFinite,
            color: context.colors.surfaceVariant,
            child: Text(
              "無網際網路連線",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: bodyPages,
        ),
      );
    }
  }
}
