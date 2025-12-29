import 'package:dpip/widgets/list/list_item_tile.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/home/home_display_mode.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsLayoutPage extends StatelessWidget {
  const SettingsLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Section(
          children: [
            Selector<SettingsUserInterfaceModel, bool>(
              selector: (context, model) => model.isEnabled(.radar),
              builder: (context, isEnabled, child) {
                return SectionListTile(
                  isFirst: true,
                  leading: ContainedIcon(
                    Symbols.radar_rounded,
                    color: Colors.blueAccent,
                  ),
                  title: Text('雷達回波'.i18n),
                  subtitle: Text('顯示即時雷達回波圖'.i18n),
                  trailing: Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      context.userInterface.toggleSection(.radar, value);
                    },
                  ),
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
        ),
      ],
    );
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
                      '自訂首頁顯示的區塊'.i18n,
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
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
