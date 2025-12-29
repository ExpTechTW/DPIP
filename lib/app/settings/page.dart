import 'package:flutter/material.dart';

import 'package:clipboard/clipboard.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/app/debug/logs/page.dart';
import 'package:dpip/app/settings/donate/page.dart';
import 'package:dpip/app/settings/locale/page.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/app/settings/map/page.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/app/settings/proxy/page.dart';
import 'package:dpip/app/settings/theme/page.dart';
import 'package:dpip/app/settings/unit/page.dart';
import 'package:dpip/core/device_info.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

import 'layout/page.dart';

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

  static const route = '/settings';

  Widget _buildIconContainer({
    required Widget icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconTheme(
        data: IconThemeData(color: color, size: 20),
        child: icon,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primaryContainer.withValues(alpha: 0.6),
            context.colors.tertiaryContainer.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary,
                  context.colors.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '設定'.i18n,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '自訂你的 DPIP 使用體驗'.i18n,
                  style: context.texts.bodyMedium?.copyWith(
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

  Widget _buildSectionCard({
    required BuildContext context,
    required String? label,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                label,
                style: context.texts.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appInfo =
        '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo =
        '${DeviceInfo.model}${DeviceInfo.serial != null ? '' : ''}(${DeviceInfo.version})';

    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 16 + context.padding.bottom),
      children: [
        _buildHeader(context),

        // 位置
        _buildSectionCard(
          context: context,
          label: '位置'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.pin_drop_rounded),
                color: Colors.red,
              ),
              title: Text('所在地'.i18n),
              subtitle: Text('設定你的所在地來接收當地的即時資訊'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsLocationPage.route),
            ),
          ],
        ),

        // 介面
        _buildSectionCard(
          context: context,
          label: '介面'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.grid_view_rounded),
                color: Colors.blue,
              ),
              title: Text('佈局'.i18n),
              subtitle: Text('調整 DPIP 的佈局樣式'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsLayoutPage.route),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.brush_rounded),
                color: Colors.purple,
              ),
              title: Text('主題'.i18n),
              subtitle: Text('調整 DPIP 整體的外觀與顏色'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsThemePage.route),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.translate_rounded),
                color: Colors.teal,
              ),
              title: Text('語言'.i18n),
              subtitle: Text('調整 DPIP 的顯示語言'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsLocalePage.route),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.percent_rounded),
                color: Colors.orange,
              ),
              title: Text('單位'.i18n),
              subtitle: Text('調整 DPIP 顯示數值時使用的單位'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsUnitPage.route),
            ),
            SectionListTile(
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.map_rounded),
                color: Colors.green,
              ),
              title: Text('地圖'.i18n),
              subtitle: Text('調整 DPIP 地圖的設定'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsMapPage.route),
            ),
          ],
        ),

        // 通知
        _buildSectionCard(
          context: context,
          label: '通知'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.notifications_rounded),
                color: Colors.amber,
              ),
              title: Text('通知'.i18n),
              subtitle: Text('推播通知設定與通知音效測試'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsNotifyPage.route),
            ),
          ],
        ),

        // 網路
        _buildSectionCard(
          context: context,
          label: '網路'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.settings_ethernet_rounded),
                color: Colors.blueGrey,
              ),
              title: Text('HTTP 代理'.i18n),
              subtitle: Text(
                Preference.proxyEnabled == true
                    ? '${Preference.proxyHost ?? ''}:${Preference.proxyPort ?? ''}'
                    : '未啟用'.i18n,
              ),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(SettingsProxyPage.route),
            ),
          ],
        ),

        // 資訊
        _buildSectionCard(
          context: context,
          label: '資訊'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.newspaper_rounded),
                color: Colors.indigo,
              ),
              title: Text('公告'.i18n),
              subtitle: Text('掌握 ExpTech Studio 的最新公告與資訊'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/announcement'),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.update_rounded),
                color: Colors.cyan,
              ),
              title: Text('更新日誌'.i18n),
              subtitle: Text('瀏覽 DPIP 的歷次更新紀錄'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/changelog'),
            ),
            SectionListTile(
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.book_rounded),
                color: Colors.brown,
              ),
              title: Text('第三方套件授權'.i18n),
              subtitle: Text('DPIP 的實現歸功於開放源始碼'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push('/license'),
            ),
          ],
        ),

        // 贊助
        _buildDonateCard(context),

        // ExpTech Studio 連結
        _buildSectionCard(
          context: context,
          label: 'ExpTech Studio',
          children: [
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return SectionListTile(
                  isFirst: true,
                  leading: _buildIconContainer(
                    icon: const Icon(SimpleIcons.github),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  title: const Text('Github'),
                  subtitle: const Text('ExpTechTW'),
                  trailing: const Icon(Symbols.arrow_outward_rounded),
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/ExpTechTW/DPIP-Pocket'),
                  ),
                );
              },
            ),
            _buildSocialTile(
              context: context,
              icon: const Icon(SimpleIcons.discord),
              color: const Color(0xFF5865F2),
              title: 'Discord',
              subtitle: '.gg/exptech-studio',
              url: 'https://exptech.com.tw/dc',
            ),
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return SectionListTile(
                  leading: _buildIconContainer(
                    icon: const Icon(SimpleIcons.threads),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  title: const Text('Threads'),
                  subtitle: const Text('@dpip.tw'),
                  trailing: const Icon(Symbols.arrow_outward_rounded),
                  onTap: () =>
                      launchUrl(Uri.parse('https://www.threads.net/@dpip.tw')),
                );
              },
            ),
            SectionListTile(
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(SimpleIcons.youtube),
                color: const Color(0xFFFF0000),
              ),
              title: const Text('Youtube'),
              subtitle: const Text('@exptechtw'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(
                Uri.parse('https://www.youtube.com/@exptechtw/live'),
              ),
            ),
          ],
        ),

        // 下載
        _buildSectionCard(
          context: context,
          label: '下載'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              leading: _buildIconContainer(
                icon: const Icon(SimpleIcons.appstore),
                color: const Color(0xFF0D96F6),
              ),
              title: const Text('App Store'),
              subtitle: const Text('iOS'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(
                Uri.parse('https://apps.apple.com/tw/app/dpip/id6468026362'),
              ),
            ),
            SectionListTile(
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(SimpleIcons.googleplay),
                color: const Color(0xFF34A853),
              ),
              title: const Text('Google Play'),
              subtitle: const Text('Android'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => launchUrl(
                Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.exptech.dpip',
                ),
              ),
            ),
          ],
        ),

        // 除錯
        _buildSectionCard(
          context: context,
          label: '除錯'.i18n,
          children: [
            SectionListTile(
              isFirst: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.info_rounded),
                color: Colors.grey,
              ),
              title: Text('應用程式版本'.i18n),
              trailing: Text(appInfo),
              onLongPress: () => FlutterClipboard.copy(appInfo),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.smartphone_rounded),
                color: Colors.grey,
              ),
              title: Text('裝置資訊'.i18n),
              trailing: Text(deviceInfo),
              onLongPress: () => FlutterClipboard.copy(deviceInfo),
            ),
            SectionListTile(
              leading: _buildIconContainer(
                icon: const Icon(Symbols.key_rounded),
                color: Colors.grey,
              ),
              title: Text('複製通知 Token'.i18n),
              trailing: const Icon(Symbols.content_copy_rounded),
              onTap: () => FlutterClipboard.copy(Preference.notifyToken),
            ),
            SectionListTile(
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.bug_report_rounded),
                color: Colors.grey,
              ),
              title: Text('App 日誌'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => context.push(AppDebugLogsPage.route),
            ),
          ],
        ),

        // Footer
        _buildFooter(context),
      ],
    );
  }

  Widget _buildSocialTile({
    required BuildContext context,
    required Widget icon,
    required Color color,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return SectionListTile(
      leading: _buildIconContainer(icon: icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Symbols.arrow_outward_rounded),
      onTap: () => launchUrl(Uri.parse(url)),
    );
  }

  Widget _buildDonateCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFFA500).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(SettingsDonatePage.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Symbols.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '贊助我們'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB8860B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '幫助我們維護伺服器的穩定和長久發展'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: const Color(0xFFB8860B).withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Symbols.earthquake_rounded,
              color: context.colors.onSurfaceVariant,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ExpTech Studio © 2025',
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '任何資訊應以中央氣象署發布之內容為準。'.i18n,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
