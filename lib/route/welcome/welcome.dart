import 'package:dpip/app/dpip.dart';
import 'package:dpip/route/welcome/pages/disclaimer.dart';
import 'package:dpip/route/welcome/pages/hello_page.dart';
import 'package:dpip/route/welcome/pages/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../global.dart';

class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => _WelcomeRouteState();
}

class _WelcomeRouteState extends State<WelcomeRoute> {
  PageController controller = PageController();
  int currentPageIndex = 0;
  List<Widget> pages = const [WelcomeHelloPage(), WelcomePermissionPage(), WelcomeDisclaimerPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF009E8B),
              Color(0xFF203864),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible: currentPageIndex > 0,
                      child: IconButton(
                        icon: const Icon(Symbols.arrow_back),
                        onPressed: () {
                          setState(() => currentPageIndex--);
                          controller.animateToPage(currentPageIndex,
                              duration: Durations.medium2, curve: Easing.standard);
                        },
                      ),
                    ),
                    FilledButton(
                      child: const Text("下一頁"),
                      onPressed: () async {
                        if (currentPageIndex == pages.length - 1) {
                          await Global.preference.setString("welcomeContentVersion", "1.0.0");
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Dpip()),
                          );
                        } else {
                          setState(() => currentPageIndex++);
                          controller.animateToPage(currentPageIndex,
                              duration: Durations.medium2, curve: Easing.standard);
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}