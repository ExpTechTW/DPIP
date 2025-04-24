import "package:dpip/route/settings/content/experiment.dart";
import "package:dpip/route/settings/content/locale.dart";
import "package:dpip/route/settings/content/location.dart";
import "package:dpip/route/settings/content/root.dart";
import "package:dpip/route/settings/content/theme.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/page_route_builder/forward_back.dart";
import "package:flutter/material.dart";

class SettingsRoute extends StatefulWidget {
  final String? initialRoute;

  const SettingsRoute({super.key, this.initialRoute});

  @override
  State<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  final controller = ScrollController();
  final backTransition = const Interval(0, 0.5, curve: Easing.emphasizedAccelerate);
  final forwardTransition = const Interval(0.5, 1, curve: Easing.emphasizedDecelerate);

  List<String> history = [];
  double savedScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navKey.currentState?.pushNamed(widget.initialRoute!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeTitle = {
      "/": context.i18n.settings,
      "/locale": context.i18n.settings_locale,
      "/location": context.i18n.settings_location,
      "/theme": context.i18n.settings_theme,
      "/experiment": context.i18n.advanced_features,
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
            controller.animateTo(savedScrollOffset, duration: Durations.long4, curve: Easing.standard);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: NestedScrollView(
          controller: controller,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar.large(
                pinned: true,
                floating: true,
                title: Builder(
                  builder: (context) {
                    return Text(routeTitle[history.last] ?? context.i18n.settings);
                  },
                ),
              ),
            ];
          },
          body: Navigator(
            key: navKey,
            initialRoute: "/",
            onGenerateInitialRoutes: (navigator, initialRoute) {
              history.add(initialRoute);

              return [
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const SettingsRootView(),
                  transitionDuration: Durations.long4,
                  reverseTransitionDuration: Durations.long4,
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var slide = Tween(
                      begin: Offset.zero,
                      end: const Offset(-0.2, 0.0),
                    ).chain(CurveTween(curve: backTransition));

                    var fade = Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: backTransition));

                    return SlideTransition(
                      position: secondaryAnimation.drive(slide),
                      child: FadeTransition(opacity: secondaryAnimation.drive(fade), child: child),
                    );
                  },
                ),
              ];
            },
            onGenerateRoute: (settings) {
              setState(() {
                history.add(settings.name!);
              });

              savedScrollOffset = controller.position.pixels;
              controller.animateTo(0, duration: Durations.long4, curve: Easing.standard);

              switch (settings.name) {
                case "/locale":
                  return ForwardBackPageRouteBuilder(page: const SettingsLocaleView());
                case "/location":
                  return ForwardBackPageRouteBuilder(page: const SettingsLocationView());
                case "/theme":
                  return ForwardBackPageRouteBuilder(page: const SettingsThemeView());
                case "/experiment":
                  return ForwardBackPageRouteBuilder(page: const SettingsExperimentView());
              }

              return null;
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
