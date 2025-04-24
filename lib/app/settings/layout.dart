import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsLayout extends StatefulWidget {
  final Widget child;

  const SettingsLayout({super.key, required this.child});

  @override
  State<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<SettingsLayout> {
  final controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: controller,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              pinned: true,
              floating: true,
              title: Text('設定'),
              leading: BackButton(
                onPressed: () {
                  context.pop();
                },
              ),
            ),
          ];
        },
        body: widget.child,
      ),
    );
  }
}
