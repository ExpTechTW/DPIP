import 'package:flutter/material.dart';

import 'package:dpip/app/home/_widgets/mode_toggle_button.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class DateTimelineItem extends StatelessWidget {
  final String date;
  final bool first;
  final bool last;
  final HomeMode? mode;
  final ValueChanged<HomeMode>? onModeChanged;

  const DateTimelineItem(
    this.date, {
    super.key,
    this.first = false,
    this.last = false,
    this.mode,
    this.onModeChanged,
  });

  void _showModeMenu(BuildContext context) {
    if (mode == null || onModeChanged == null) return;

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
      items: HomeMode.values.map((m) {
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
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: mode == m ? context.colors.primary : context.colors.onSurface,
                  fontWeight: mode == m ? FontWeight.bold : FontWeight.normal,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0,
                  top: first ? 21 : 0,
                  bottom: last ? null : 0,
                  height: last ? 21 : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(top: 0, bottom: 0, width: 1, child: Container(color: context.colors.outlineVariant)),
                      SizedBox(
                        width: 42,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: InkWell(
                    onTap: mode != null && onModeChanged != null ? () => _showModeMenu(context) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.colors.secondaryContainer,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                              style: context.theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: context.colors.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
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
                            style: context.theme.textTheme.labelLarge?.copyWith(
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
