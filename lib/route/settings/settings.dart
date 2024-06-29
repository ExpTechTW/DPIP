import 'package:dpip/route/settings/content/location.dart';
import 'package:dpip/route/settings/content/root.dart';
import 'package:dpip/route/settings/content/theme.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({super.key});

  @override
  State<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  List<String> history = [];

  @override
  Widget build(BuildContext context) {
    final routeTitle = {
      "/": context.i18n.settings,
      "/location": "所在地",
      "/theme": "主題色",
    };

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }

        if (navKey.currentState!.canPop()) {
          final pop = await navKey.currentState!.maybePop();
          if (pop) {
            setState(() {
              history.removeLast();
            });
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar.large(
                title: Builder(
                  builder: (context) {
                    return Text(routeTitle[history.last] ?? context.i18n.settings);
                  },
                ),
              )
            ];
          },
          body: Navigator(
            key: navKey,
            onGenerateRoute: (settings) {
              Widget child;

              if (settings.name != "/") {
                setState(() {
                  history.add(settings.name!);
                });
              } else {
                history.add(settings.name!);
              }

              switch (settings.name) {
                case "/location":
                  child = const SettingsLocationView();
                  break;
                case "/theme":
                  child = const SettingsThemeView();
                  break;
                default:
                  return PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsRootView(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      var slide = Tween(
                        begin: Offset.zero,
                        end: const Offset(-0.2, 0.0),
                      ).chain(CurveTween(curve: Easing.standardAccelerate));

                      var fade = Tween(
                        begin: 1.0,
                        end: 0.0,
                      ).chain(CurveTween(curve: Easing.standardAccelerate));

                      return SlideTransition(
                        position: secondaryAnimation.drive(slide),
                        child: FadeTransition(opacity: secondaryAnimation.drive(fade), child: child),
                      );
                    },
                  );
              }

              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => child,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  var slide = Tween(
                    begin: const Offset(0.2, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Easing.standardDecelerate));

                  var fade = Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).chain(CurveTween(curve: Easing.standardDecelerate));

                  return SlideTransition(
                    position: animation.drive(slide),
                    child: FadeTransition(opacity: animation.drive(fade), child: child),
                  );
                },
              );
            },
            onPopPage: (route, result) {
              return route.didPop(result);
            },
          ),
        ),
      ),
    );
  }
}
