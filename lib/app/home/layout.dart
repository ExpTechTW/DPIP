import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NewHomeLayout extends StatefulWidget {
  final Widget child;

  const NewHomeLayout({required this.child, super.key});

  @override
  State<NewHomeLayout> createState() => _NewHomeLayoutState();
}

class _NewHomeLayoutState extends State<NewHomeLayout> with TickerProviderStateMixin {
  late final _scrollAnimator = AnimationController(vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.child,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: context.padding.top + 8,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topCenter,
                  end: .bottomCenter,
                  colors: [
                    context.colors.surface,
                    context.colors.surface.withValues(alpha: .75),
                    context.colors.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: context.padding.top + 8,
            right: 8,
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .end,
              children: [
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: Icon(
                    Symbols.notifications_rounded,
                    fill: 1,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => SettingsIndexRoute().push(context),
                  icon: Icon(
                    Symbols.settings_rounded,
                    fill: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const .symmetric(horizontal: 96, vertical: 8),
        child: NavigationBarM3E(
          destinations: [
            NavigationDestinationM3E(
              icon: Icon(Symbols.home_rounded),
              label: '主頁',
            ),
            NavigationDestinationM3E(
              icon: Icon(Symbols.category_rounded),
              label: '小工具',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollAnimator.dispose();
    super.dispose();
  }
}
