import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class SettingsLayoutPage extends StatelessWidget {
  const SettingsLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        final enabledSections = model.homeSections;
        final disabledSections = HomeDisplaySection.values
            .where((s) => !enabledSections.contains(s))
            .toList();

        return ListView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (enabledSections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '顯示中'.i18n,
                  style: context.texts.labelLarge?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enabledSections.length,
                onReorder: model.reorderSection,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final section = enabledSections[index];
                  final details = _getSectionDetails(section);
                  return _buildSectionCard(
                    context,
                    key: ValueKey(section),
                    icon: details.icon,
                    iconColor: details.color,
                    title: details.title,
                    subtitle: details.subtitle,
                    value: true,
                    onChanged: (v) => model.toggleSection(section, v),
                    isReorderable: true,
                  );
                },
              ),
            ],
            if (disabledSections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '已隱藏'.i18n,
                  style: context.texts.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              ...disabledSections.map(
                (section) {
                  final details = _getSectionDetails(section);
                  return _buildSectionCard(
                    context,
                    key: ValueKey(section),
                    icon: details.icon,
                    iconColor: details.color,
                    title: details.title,
                    subtitle: details.subtitle,
                    value: false,
                    onChanged: (v) => model.toggleSection(section, v),
                    isReorderable: false,
                  );
                },
              ),
              Selector<SettingsUserInterfaceModel, bool>(
                selector: (context, model) => model.isEnabled(.forecast),
                builder: (context, isEnabled, child) {
                  return SectionListTile(
                    leading: ContainedIcon(
                      Symbols.radar_rounded,
                      color: Colors.orangeAccent,
                    ),
                    title: Text('天氣預報'.i18n),
                    subtitle: Text('顯示未來 24 小時的天氣預報'.i18n),
                    trailing: Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        context.userInterface.toggleSection(.forecast, value);
                      },
                    ),
                  );
                },
              ),
              Selector<SettingsUserInterfaceModel, bool>(
                selector: (context, model) => model.isEnabled(.wind),
                builder: (context, isEnabled, child) {
                  return SectionListTile(
                    leading: ContainedIcon(
                      Symbols.wind_power_rounded,
                      color: Colors.orangeAccent,
                    ),
                    title: Text('風向'.i18n),
                    subtitle: Text('顯示風向與風力級數'.i18n),
                    trailing: Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        context.userInterface.toggleSection(.wind, value);
                      },
                    ),
                  );
                },
              ),
              Selector<SettingsUserInterfaceModel, bool>(
                selector: (context, model) => model.isEnabled(.history),
                builder: (context, isEnabled, child) {
                  return SectionListTile(
                    isLast: true,
                    leading: ContainedIcon(
                      Symbols.history_rounded,
                      color: Colors.greenAccent,
                    ),
                    title: Text('歷史事件'.i18n),
                    subtitle: Text('顯示地震與災害歷史紀錄'.i18n),
                    trailing: Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        context.userInterface.toggleSection(.history, value);
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  ({IconData icon, Color color, String title, String subtitle})
  _getSectionDetails(HomeDisplaySection section) {
    switch (section) {
      case HomeDisplaySection.radar:
        return (
          icon: Symbols.radar_rounded,
          color: Colors.blue,
          title: '雷達回波'.i18n,
          subtitle: '顯示即時雷達回波圖'.i18n,
        );
      case HomeDisplaySection.forecast:
        return (
          icon: Symbols.partly_cloudy_day_rounded,
          color: Colors.orange,
          title: '天氣預報(24h)'.i18n,
          subtitle: '顯示未來 24 小時天氣預報'.i18n,
        );
      case HomeDisplaySection.history:
        return (
          icon: Symbols.history_rounded,
          color: Colors.green,
          title: '歷史事件'.i18n,
          subtitle: '顯示地震與災害歷史紀錄'.i18n,
        );
      case HomeDisplaySection.wind:
        return (
          icon: Symbols.wind_power_rounded,
          color: Colors.purple,
          title: '風向'.i18n,
          subtitle: '顯示風向與風力級數'.i18n,
        );
      case HomeDisplaySection.community:
        return (
          icon: Symbols.people_alt_rounded,
          color: Colors.teal,
          title: '社群動態'.i18n,
          subtitle: '顯示來自社群的即時資訊'.i18n,
        );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Symbols.dashboard_customize_rounded,
                  color: context.colors.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '首頁樣式'.i18n,
                      style: context.texts.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '長按可拖曳排序顯示順序'.i18n,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isReorderable,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isReorderable) ...[
                  Icon(
                    Symbols.drag_handle_rounded,
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: value
                        ? iconColor.withValues(alpha: 0.15)
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: value
                        ? iconColor
                        : context.colors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: value
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant.withValues(
                            alpha: value ? 1 : 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
