import 'package:dpip/app/dpip.dart';
import 'package:dpip/global.dart';
import 'package:dpip/route/welcome/pages/about.dart';
import 'package:dpip/route/welcome/pages/exptech.dart';
import 'package:dpip/route/welcome/pages/notice.dart';
import 'package:dpip/route/welcome/pages/permission.dart';
import 'package:flutter/material.dart';

class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => WelcomeRouteState();
}

class WelcomeRouteState extends State<WelcomeRoute> {
  static WelcomeRouteState? of(BuildContext context) {
    return context.findAncestorStateOfType<WelcomeRouteState>();
  }

  PageController controller = PageController();

  void nextPage() {
    controller.nextPage(duration: Durations.medium4, curve: Easing.emphasizedDecelerate);
  }

  void prevPage() {
    controller.previousPage(duration: Durations.short4, curve: Easing.standard);
  }

  void complete() {
    Global.preference.setBool("welcome-1.0.0", true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Dpip(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          WelcomeAboutPage(),
          WelcomeExpTechPage(),
          WelcomeNoticePage(),
          WelcomePermissionPage(),
        ],
      ),
    );
  }
}
