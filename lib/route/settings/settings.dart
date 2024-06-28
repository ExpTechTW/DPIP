import 'package:dpip/route/settings/location/location.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsRoute extends StatefulWidget {
  const SettingsRoute({super.key});

  @override
  State<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<SettingsRoute> {
  @override
  Widget build(BuildContext context) {
    const tileTitleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text(context.i18n.settings),
            )
          ];
        },
        body: ListView(
          children: [
            const ListTileGroupHeader(title: "位置"),
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Symbols.pin_drop),
              ),
              title: const Text(
                "所在地",
                style: tileTitleTextStyle,
              ),
              subtitle: const Text("調整所在地來接收即時天氣資訊、地震預估震度以及地震波預估抵達秒數等"),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsLocationView(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Easing.standardDecelerate;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      final offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
