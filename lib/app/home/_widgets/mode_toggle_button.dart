/// Mode toggle button and [HomeMode] enum for the home screen history filter.
library;

import 'dart:ui';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Describes the four history display modes available on the home screen.
enum HomeMode {
  /// Nationwide view showing currently active events.
  nationalActive,

  /// Nationwide view showing historical events.
  nationalHistory,

  /// Local view showing currently active events near the user's location.
  localActive,

  /// Local view showing historical events near the user's location.
  localHistory,
}

/// Convenience accessors for [HomeMode] display properties.
extension HomeModeExtension on HomeMode {
  /// The localised label shown in the UI for this mode.
  String get label {
    switch (this) {
      case .nationalActive:
        return '全國 · 生效中'.i18n;
      case .nationalHistory:
        return '全國 · 歷史'.i18n;
      case .localActive:
        return '所在地 · 生效中'.i18n;
      case .localHistory:
        return '所在地 · 歷史'.i18n;
    }
  }

  /// The icon that represents this mode.
  IconData get icon {
    switch (this) {
      case .nationalActive:
      case .nationalHistory:
        return Symbols.public_rounded;
      case .localActive:
      case .localHistory:
        return Symbols.location_on_rounded;
    }
  }

  /// Whether this mode shows nationwide data rather than local data.
  bool get isNational {
    return this == .nationalActive || this == .nationalHistory;
  }

  /// Whether this mode shows currently active events rather than history.
  bool get isActive {
    return this == .nationalActive || this == .localActive;
  }
}

/// A blurred glass-effect button that opens a popup menu to switch
/// [HomeMode].
class ModeToggleButton extends StatelessWidget {
  /// The mode currently displayed by the button.
  final HomeMode currentMode;

  /// Called with the newly selected [HomeMode] when the user makes a choice.
  final ValueChanged<HomeMode> onModeChanged;

  /// Creates a [ModeToggleButton].
  const ModeToggleButton({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  void _showModeMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        context.navigator.overlay?.context.findRenderObject() as RenderBox?;

    if (button == null || overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<HomeMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
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
                color: currentMode == mode
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
              Text(
                mode.label,
                style: context.texts.bodyMedium?.copyWith(
                  color: currentMode == mode
                      ? context.colors.primary
                      : context.colors.onSurface,
                  fontWeight: currentMode == mode
                      ? .bold
                      : .normal,
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
      borderRadius: .circular(24),
      child: ClipRRect(
        borderRadius: .circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: .circular(24),
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.4),
              ),
              color: context.colors.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
            ),
            child: InkWell(
              onTap: () => _showModeMenu(context),
              borderRadius: .circular(24),
              child: Padding(
                padding: const .symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: .min,
                  spacing: 8,
                  children: [
                    Icon(
                      currentMode.icon,
                      size: 20,
                      color: context.colors.outline,
                    ),
                    Text(
                      currentMode.label,
                      style: context.texts.bodyLarge?.copyWith(
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
