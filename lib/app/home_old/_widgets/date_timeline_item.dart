/// Timeline item widget that shows a date header with an optional mode selector.
library;

import 'package:dpip/app/home_old/_widgets/mode_toggle_button.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// Renders a date-labelled row in the home history timeline.
///
/// When [mode] and [onModeChanged] are provided the label is tappable and
/// opens a popup menu for switching [HomeMode]. Pass [isOutOfService] as
/// `true` to restrict available modes to national-only options.
class DateTimelineItem extends StatelessWidget {
  /// The formatted date string displayed in the chip.
  final String date;

  /// Whether this is the first item in the timeline.
  final bool first;

  /// Whether this is the last item in the timeline.
  final bool last;

  /// The currently active [HomeMode], or `null` to hide the mode indicator.
  final HomeMode? mode;

  /// Called with the newly selected [HomeMode] when the user changes modes.
  final ValueChanged<HomeMode>? onModeChanged;

  /// When `true`, limits the mode menu to national-only entries.
  final bool isOutOfService;

  /// Creates a [DateTimelineItem] for the given [date].
  const DateTimelineItem(
    this.date, {
    super.key,
    this.first = false,
    this.last = false,
    this.mode,
    this.onModeChanged,
    this.isOutOfService = false,
  });

  void _showModeMenu(BuildContext context) {
    if (mode == null || onModeChanged == null) return;

    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay = context.navigator.overlay?.context.findRenderObject() as RenderBox?;

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

    // 如果在服務區外，只顯示全國模式
    final availableModes = isOutOfService
        ? HomeMode.values.where((m) => m.isNational).toList()
        : HomeMode.values;

    showMenu<HomeMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      elevation: 8,
      items: availableModes.map((m) {
        return PopupMenuItem<HomeMode>(
          value: m,
          child: Row(
            spacing: 12,
            children: [
              Icon(
                m.icon,
                size: 20,
                color: mode == m ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
              Text(
                m.label,
                style: context.texts.bodyMedium?.copyWith(
                  color: mode == m ? context.colors.primary : context.colors.onSurface,
                  fontWeight: mode == m ? .bold : .normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedMode) {
      if (selectedMode != null && selectedMode != mode) {
        onModeChanged!(selectedMode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 16),
            child: Stack(
              alignment: .centerLeft,
              children: [
                Positioned(
                  left: 0,
                  top: first ? 21 : 0,
                  bottom: last ? null : 0,
                  height: last ? 21 : null,
                  child: Stack(
                    alignment: .center,
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(
                          color: context.colors.outlineVariant,
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            shape: .circle,
                            color: context.colors.outlineVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const .only(top: 16, bottom: 8),
                  child: InkWell(
                    onTap: mode != null && onModeChanged != null
                        ? () => _showModeMenu(context)
                        : null,
                    borderRadius: .circular(8),
                    child: Container(
                      padding: const .all(8),
                      decoration: BoxDecoration(
                        borderRadius: .circular(8),
                        color: context.colors.secondaryContainer,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 6,
                        children: [
                          if (mode != null) ...[
                            Icon(
                              mode!.icon,
                              size: 16,
                              color: context.colors.onSecondaryContainer,
                            ),
                            Text(
                              mode!.label,
                              style: context.texts.labelMedium?.copyWith(
                                height: 1,
                                color: context.colors.onSecondaryContainer,
                                fontWeight: .bold,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              color: context.colors.onSecondaryContainer.withValues(alpha: 0.3),
                            ),
                          ],
                          Text(
                            date,
                            style: context.texts.labelLarge?.copyWith(
                              height: 1,
                              color: context.colors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
