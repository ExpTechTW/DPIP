/// Experimental features settings page.
library;

import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/experimental.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

/// A page for toggling experimental (in-development) features.
///
/// Each feature shows a confirmation dialog with a countdown before it can be
/// enabled. Disabled features can be turned off immediately.
class SettingsExperimentalPage extends StatelessWidget {
  /// Creates a [SettingsExperimentalPage].
  const SettingsExperimentalPage({super.key});

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      margin: const .fromLTRB(16, 16, 16, 0),
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: .circular(16),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          const ContainedIcon(
            Symbols.warning_rounded,
            color: Colors.amberAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  '注意'.i18n,
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: .w600,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '這些功能仍在開發中，可能會不穩定或在未來的版本中變更。'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingsHeader(
          icon: Symbols.science_rounded,
          title: Text('實驗性功能'.i18n),
          subtitle: Text('搶先體驗開發中的新功能'.i18n),
        ),
        _buildWarningCard(context),
        const SizedBox(height: 16),
        SegmentedList(
          children: [
            Selector<SettingsExperimentalModel, bool>(
              selector: (_, model) => model.experimental__launchToMonitor,
              builder: (context, experimental__launchToMonitor, child) {
                return SegmentedListTile(
                  isFirst: true,
                  leading: const ContainedIcon(
                    Symbols.monitor_heart_rounded,
                    color: Colors.red,
                  ),
                  title: Text('啟動時進入強震監視器'.i18n),
                  subtitle: Text('開啟 App 時直接進入強震監視器地圖'.i18n),
                  trailing: Switch(
                    value: experimental__launchToMonitor,
                    onChanged: context.experimental.set_experimental__launchToMonitor,
                  ),
                );
              },
            ),
            Selector<SettingsExperimentalModel, bool>(
              selector: (_, model) => model.experimental__eewAllSource,
              builder: (context, experimental__eewAllSource, child) {
                return SegmentedListTile(
                  leading: const ContainedIcon(
                    Symbols.earthquake_rounded,
                    color: Colors.orange,
                  ),
                  title: Text('不限制非 CWA 來源'.i18n),
                  subtitle: Text('顯示所有來源的地震速報資料'.i18n),
                  trailing: Switch(
                    value: experimental__eewAllSource,
                    onChanged: context.experimental.set_experimental__eewAllSource,
                  ),
                );
              },
            ),
            Selector<SettingsExperimentalModel, bool>(
              selector: (_, model) => model.experimental__newHomeScreen,
              builder: (context, experimental__newHomeScreen, child) {
                return SegmentedListTile(
                  isLast: true,
                  leading: const ContainedIcon(
                    Symbols.home_rounded,
                    color: Colors.blueAccent,
                  ),
                  title: Text('新首頁樣式'.i18n),
                  subtitle: Text('使用新的首頁，目前還在開發中\n需要重新啟動 DPIP 來套用設定'.i18n),
                  trailing: Switch(
                    value: experimental__newHomeScreen,
                    onChanged: context.experimental.set_experimental__newHomeScreen,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
