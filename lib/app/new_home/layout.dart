import 'package:dpip/core/i18n.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color.dart';
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
                    context.colors.surface / 40,
                    context.colors.surface / 0,
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
                  icon: const Icon(
                    Symbols.notifications_rounded,
                    fill: 1,
                  ),
                  style: IconButton.styleFrom(
                    elevation: 4,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => const SettingsIndexRoute().push(context),
                  icon: const Icon(
                    Symbols.settings_rounded,
                    fill: 1,
                  ),
                  style: IconButton.styleFrom(
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: NavigationBarM3E(
        elevation: 2,
        padding: const .symmetric(horizontal: 72, vertical: 8),
        density: .compact,
        destinations: [
          NavigationDestinationM3E(
            icon: const Icon(Symbols.home_rounded),
            selectedIcon: const Icon(Symbols.home_rounded, fill: 1),
            label: '首頁'.i18n,
          ),
          NavigationDestinationM3E(
            icon: const Icon(Symbols.map_rounded),
            selectedIcon: const Icon(Symbols.map_rounded, fill: 1),
            label: '地圖'.i18n,
          ),
          NavigationDestinationM3E(
            icon: const Icon(Symbols.category_rounded),
            selectedIcon: const Icon(Symbols.category_rounded, fill: 1),
            label: '小工具'.i18n,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollAnimator.dispose();
    super.dispose();
  }
}
