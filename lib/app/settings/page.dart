/// Settings index page listing all top-level settings categories.
library;

import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';

/// The root settings page.
///
/// Displays a scrollable list of setting categories (location, UI, notifications,
/// network, info, links, and debug). Tap any row to navigate to that section.
class SettingsIndexPage extends StatelessWidget {
  /// Creates a [SettingsIndexPage].
  const SettingsIndexPage({super.key});

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const .fromLTRB(16, 0, 16, 8),
      padding: const .all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primaryContainer.withValues(alpha: 0.6),
            context.colors.tertiaryContainer.withValues(alpha: 0.4),
          ],
          begin: .topLeft,
          end: .bottomRight,
        ),
        borderRadius: .circular(20),
        border: .all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const .all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary,
                  context.colors.tertiary,
                ],
                begin: .topLeft,
                end: .bottomRight,
              ),
              borderRadius: .circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Symbols.settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                TitleText.large('設定'.i18n, weight: .bold),
                BodyText.large('自訂你的 DPIP 使用體驗'.i18n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appInfo = '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo = '${DeviceInfo.model}(${DeviceInfo.version})';

    return ListView(
      padding: .only(top: 16, bottom: 16 + context.padding.bottom),
      children: [
        _buildHeader(context),

        // 介面
        SegmentedList(
          label: Text('介面'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                Symbols.dashboard_rounded,
                color: Colors.lightBlueAccent,
              ),
              title: Text('版面'.i18n),
              subtitle: Text('調整首頁的版面樣式'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsLayoutRoute().push(context),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                Symbols.map_rounded,
                color: Colors.greenAccent,
              ),
              title: Text('地圖'.i18n),
              subtitle: Text('調整地圖的顯示樣式'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsMapRoute().push(context),
            ),
          ],
        ),

        // 網路
        SegmentedList(
          label: Text('網路'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              isLast: true,
              leading: ContainedIcon(
                Symbols.settings_ethernet_rounded,
                color: Colors.blueGrey,
              ),
              title: Text('HTTP 代理'.i18n),
              subtitle: Text('調整 HTTP 代理伺服器設定'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsProxyRoute().push(context),
            ),
          ],
        ),

        // 資訊
        /*SegmentedList(
          label: Text('資訊'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                Symbols.newspaper_rounded,
                color: Colors.indigoAccent,
              ),
              title: Text('公告'.i18n),
              subtitle: Text('掌握 ExpTech Studio 的最新公告與資訊'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => AnnouncementRoute().push(context),
            ),
          ],
        ),*/

        // 下載
        SegmentedList(
          label: Text('下載'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                SimpleIcons.appstore,
                color: SimpleIconColors.appstore,
              ),
              title: const Text('App Store'),
              subtitle: const Text('iOS'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => 'https://apps.apple.com/tw/app/dpip/id6468026362'.launch(),
              onLongPress: () => 'https://apps.apple.com/tw/app/dpip/id6468026362'.copy(),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                SimpleIcons.googleplay,
                color: switch (context.theme.brightness) {
                  .light => SimpleIconColors.googleplay,
                  .dark => SimpleIconColors.googleplay.inverted,
                },
              ),
              title: const Text('Google Play'),
              subtitle: const Text('Android'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () =>
                  'https://play.google.com/store/apps/details?id=com.exptech.dpip'.launch(),
              onLongPress: () =>
                  'https://play.google.com/store/apps/details?id=com.exptech.dpip'.copy(),
            ),
          ],
        ),

        // 除錯
        SegmentedList(
          label: Text('除錯'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                Symbols.info_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('應用程式版本'.i18n),
              trailing: Text(appInfo),
              onLongPress: () => appInfo.copy(),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.smartphone_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('裝置資訊'.i18n),
              trailing: Text(deviceInfo),
              onLongPress: () => deviceInfo.copy(),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.key_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('複製通知 Token'.i18n),
              trailing: const Icon(Symbols.content_copy_rounded),
              onTap: () => Preference.notifyToken.copy(),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.bug_report_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('App 日誌'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => AppDebugLogsRoute().push(context),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                Symbols.science_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('實驗性功能'.i18n),
              subtitle: Text('搶先體驗開發中的新功能'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsExperimentalRoute().push(context),
            ),
          ],
        ),

        // Footer
        _buildFooter(context),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 16, vertical: 64),
      child: Column(
        spacing: 4,
        children: [
          Container(
            height: 84,
            width: 84,
            margin: .only(bottom: 16),
            decoration: BoxDecoration(borderRadius: .circular(24)),
            clipBehavior: .antiAlias,
            child: Image.asset('assets/ExpTech.png'),
          ),
          TitleText.medium(
            'ExpTech Studio © 2026',
            color: context.colors.onSurfaceVariant,
            weight: .bold,
            align: .center,
          ),
          BodyText.medium(
            '任何資訊應以中央氣象署發布之內容為準'.i18n,
            color: context.colors.outline,
            align: .center,
          ),
        ],
      ),
    );
  }
}
