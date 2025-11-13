import 'dart:ui';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

enum HomeMode {
  nationalActive,
  nationalHistory,
  localActive,
  localHistory,
}

extension HomeModeExtension on HomeMode {
  String get label {
    switch (this) {
      case HomeMode.nationalActive:
        return '全國 · 生效中'.i18n;
      case HomeMode.nationalHistory:
        return '全國 · 歷史'.i18n;
      case HomeMode.localActive:
        return '所在地 · 生效中'.i18n;
      case HomeMode.localHistory:
        return '所在地 · 歷史'.i18n;
    }
  }

  IconData get icon {
    switch (this) {
      case HomeMode.nationalActive:
      case HomeMode.nationalHistory:
        return Symbols.public_rounded;
      case HomeMode.localActive:
      case HomeMode.localHistory:
        return Symbols.location_on_rounded;
    }
  }

  bool get isNational {
    return this == HomeMode.nationalActive || this == HomeMode.nationalHistory;
  }

  bool get isActive {
    return this == HomeMode.nationalActive || this == HomeMode.localActive;
  }
}

class ModeToggleButton extends StatelessWidget {
  final HomeMode currentMode;
  final ValueChanged<HomeMode> onModeChanged;

  const ModeToggleButton({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  void _showModeMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;

    if (button == null || overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<HomeMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: HomeMode.values.map((mode) {
        return PopupMenuItem<HomeMode>(
          value: mode,
          child: Row(
            spacing: 12,
            children: [
              Icon(
                mode.icon,
                size: 20,
                color: currentMode == mode ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
              Text(
                mode.label,
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: currentMode == mode ? context.colors.primary : context.colors.onSurface,
                  fontWeight: currentMode == mode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedMode) {
      if (selectedMode != null && selectedMode != currentMode) {
        onModeChanged(selectedMode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shadowColor: context.colors.shadow.withValues(alpha: 0.4),
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.4)),
              color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            child: InkWell(
              onTap: () => _showModeMenu(context),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(
                      currentMode.icon,
                      size: 20,
                      color: context.colors.outline,
                    ),
                    Text(
                      currentMode.label,
                      style: context.theme.textTheme.bodyLarge?.copyWith(
                        color: context.colors.outline,
                      ),
                    ),
                    Icon(
                      Symbols.arrow_drop_down_rounded,
                      size: 20,
                      color: context.colors.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
