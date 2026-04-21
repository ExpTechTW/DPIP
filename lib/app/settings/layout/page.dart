/// Home layout settings page for reordering and toggling displayed sections.
library;

import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// A page that lets users reorder and enable or disable home screen sections.
///
/// Drag tiles to reorder enabled sections, or tap the add/remove buttons to
/// toggle sections on and off. Requires [SettingsUserInterfaceModel] in the
/// widget tree.
class SettingsLayoutPage extends StatelessWidget {
  /// Creates a [SettingsLayoutPage].
  const SettingsLayoutPage({super.key});

  static const _sectionInfo = {
    HomeDisplaySection.radar: (
      icon: Symbols.radar_rounded,
      color: Colors.blueAccent,
      title: '雷達回波',
      subtitle: '顯示即時雷達回波圖',
    ),
    HomeDisplaySection.forecast: (
      icon: Symbols.sunny_rounded,
      color: Colors.orangeAccent,
      title: '天氣預報',
      subtitle: '顯示未來 24 小時的天氣預報',
    ),
    HomeDisplaySection.wind: (
      icon: Symbols.wind_power_rounded,
      color: Colors.tealAccent,
      title: '風向',
      subtitle: '顯示風向與風力級數',
    ),
  };

  Widget _buildSectionTile(
    BuildContext context, {
    required HomeDisplaySection section,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
    required int index,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: .only(bottom: isLast ? 0 : 2),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: .vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: ListTile(
          contentPadding: const .symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const .all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: .circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title),
          subtitle: Text(subtitle, style: context.texts.bodySmall),
          trailing: Row(
            mainAxisSize: .min,
            children: [
              IconButton(
                icon: Icon(
                  Symbols.remove_circle_outline_rounded,
                  color: context.colors.error,
                ),
                onPressed: () {
                  context.userInterface.toggleSection(section, false);
                },
                tooltip: '停用'.i18n,
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const .all(8),
                  child: Icon(
                    Symbols.drag_handle_rounded,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledTile(
    BuildContext context, {
    required HomeDisplaySection section,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      margin: .only(bottom: isLast ? 0 : 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: .vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: ListTile(
        contentPadding: const .symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Container(
          padding: const .all(8),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: .circular(8),
          ),
          child: Icon(
            icon,
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        subtitle: Text(
          subtitle,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Symbols.add_circle_outline_rounded,
            color: context.colors.primary,
          ),
          onPressed: () {
            context.userInterface.toggleSection(section, true);
          },
          tooltip: '啟用'.i18n,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsUserInterfaceModel, List<HomeDisplaySection>>(
      selector: (context, model) => List.from(model.homeSections),
      builder: (context, sections, child) {
        final disabledSections = HomeDisplaySection.values
            .where((s) => !sections.contains(s))
            .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SettingsHeader(
                icon: Symbols.dashboard_rounded,
                title: Text('版面'.i18n),
                subtitle: Text('調整首頁的版面樣式'.i18n),
              ),
            ),
            if (sections.isNotEmpty) ...[
              SliverPadding(
                padding: const .fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '拖曳調整順序'.i18n,
                    style: context.texts.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const .symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: sections.length,
                  onReorder: (oldIndex, newIndex) {
                    context.userInterface.reorderSection(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final info = _sectionInfo[section]!;
                    final isFirst = index == 0;
                    final isLast = index == sections.length - 1;

                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(section),
                      index: index,
                      child: _buildSectionTile(
                        context,
                        section: section,
                        icon: info.icon,
                        color: info.color,
                        title: info.title.i18n,
                        subtitle: info.subtitle.i18n,
                        isFirst: isFirst,
                        isLast: isLast,
                        index: index,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (disabledSections.isNotEmpty) ...[
              SliverPadding(
                padding: const .fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '已停用'.i18n,
                    style: context.texts.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const .symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = disabledSections[index];
                      final info = _sectionInfo[section]!;

                      return _buildDisabledTile(
                        context,
                        section: section,
                        icon: info.icon,
                        color: info.color,
                        title: info.title.i18n,
                        subtitle: info.subtitle.i18n,
                        isFirst: index == 0,
                        isLast: index == disabledSections.length - 1,
                      );
                    },
                    childCount: disabledSections.length,
                  ),
                ),
              ),
            ] else ...[
              SliverPadding(
                padding: const .fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '所有區塊皆已啟用'.i18n,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: .only(
                bottom: context.padding.bottom + 16,
              ),
            ),
          ],
        );
      },
    );
  }
}
