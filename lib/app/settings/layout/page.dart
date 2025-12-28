import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/home/home_display_mode.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsLayoutPage extends StatelessWidget {
  const SettingsLayoutPage({super.key});

  static const route = '/settings/layout';

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              icon: Symbols.radar_rounded,
              iconColor: Colors.blue,
              title: '雷達回波'.i18n,
              subtitle: '顯示即時雷達回波圖'.i18n,
              value: model.isEnabled(HomeDisplaySection.radar),
              onChanged: (v) => model.toggleSection(HomeDisplaySection.radar, v),
            ),
            _buildSectionCard(
              context,
              icon: Symbols.partly_cloudy_day_rounded,
              iconColor: Colors.orange,
              title: '天氣預報(24h)'.i18n,
              subtitle: '顯示未來 24 小時天氣預報'.i18n,
              value: model.isEnabled(HomeDisplaySection.forecast),
              onChanged: (v) =>
                  model.toggleSection(HomeDisplaySection.forecast, v),
            ),
            _buildSectionCard(
              context,
              icon: Symbols.history_rounded,
              iconColor: Colors.green,
              title: '歷史事件'.i18n,
              subtitle: '顯示地震與災害歷史紀錄'.i18n,
              value: model.isEnabled(HomeDisplaySection.history),
              onChanged: (v) =>
                  model.toggleSection(HomeDisplaySection.history, v),
            ),
          ],
        );
      },
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
                        : context.colors.onSurfaceVariant.withValues(alpha: 0.5),
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
                          color: context.colors.onSurfaceVariant
                              .withValues(alpha: value ? 1 : 0.7),
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
