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

class SettingsIndexPage extends StatelessWidget {
  const SettingsIndexPage({super.key});

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
    final appInfo =
        '${Global.packageInfo.version}(${Global.packageInfo.buildNumber})';
    final deviceInfo =
        '${DeviceInfo.model}${DeviceInfo.serial != null ? '' : ''}(${DeviceInfo.version})';

    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 16 + context.padding.bottom),
      children: [
        _buildHeader(context),

        // 位置
        SegmentedList(
          label: Text('位置'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              isLast: true,
              leading: _buildIconContainer(
                icon: const Icon(Symbols.pin_drop_rounded),
                color: Colors.deepOrangeAccent,
              ),
              title: Text('所在地'.i18n),
              subtitle: Text('設定你的所在地來接收當地的即時資訊'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsLocationRoute().push(context),
            ),
          ],
        ),

        // 介面
        SegmentedList(
          label: Text('介面'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                Symbols.grid_view_rounded,
                color: Colors.lightBlueAccent,
              ),
              title: Text('佈局'.i18n),
              subtitle: Text('調整 DPIP 的佈局樣式'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsLayoutRoute().push(context),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.brush_rounded,
                color: Colors.indigoAccent,
              ),
              title: Text('主題'.i18n),
              subtitle: Text('調整 DPIP 整體的外觀與顏色'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsThemeRoute().push(context),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.translate_rounded,
                color: Colors.tealAccent,
              ),
              title: Text('語言'.i18n),
              subtitle: Text('調整 DPIP 的顯示語言'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsLocaleRoute().push(context),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.percent_rounded,
                color: Colors.orangeAccent,
              ),
              title: Text('單位'.i18n),
              subtitle: Text('調整 DPIP 顯示數值時使用的單位'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsUnitRoute().push(context),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                Symbols.map_rounded,
                color: Colors.greenAccent,
              ),
              title: Text('地圖'.i18n),
              subtitle: Text('調整 DPIP 地圖的設定'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsMapRoute().push(context),
            ),
          ],
        ),

        // 通知
        SegmentedList(
          label: Text('通知'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              isLast: true,
              leading: ContainedIcon(
                Symbols.notifications_rounded,
                color: Colors.amberAccent,
              ),
              title: Text('通知'.i18n),
              subtitle: Text('推播通知設定與通知音效測試'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsNotifyRoute().push(context),
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
              subtitle: Text(
                Preference.proxyEnabled == true
                    ? '${Preference.proxyHost ?? ''}:${Preference.proxyPort ?? ''}'
                    : '未啟用'.i18n,
              ),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => SettingsProxyRoute().push(context),
            ),
          ],
        ),

        // 資訊
        SegmentedList(
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
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.update_rounded,
                color: Colors.cyanAccent,
              ),
              title: Text('更新日誌'.i18n),
              subtitle: Text('瀏覽 DPIP 的歷次更新紀錄'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => ChangelogRoute().push(context),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                Symbols.book_rounded,
                color: Colors.brown,
              ),
              title: Text('第三方套件授權'.i18n),
              subtitle: Text('DPIP 的實現歸功於開放源始碼'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => LicenseRoute().push(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 贊助
        SegmentedList(
          children: [
            SegmentedListTile(
              leading: ContainedIcon(
                Symbols.volunteer_activism_rounded,
                color: Colors.black,
                backgroundGradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: .topLeft,
                  end: .bottomRight,
                ),
              ),
              title: Text(
                '贊助我們'.i18n,
                style: .new(color: Colors.amber[600]),
              ),
              subtitle: Text('幫助我們維護伺服器的穩定和長久發展'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              tileColor: Colors.amber.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: .circular(20),
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
              ),
              onTap: () => SettingsDonateRoute().push(context),
            ),
          ],
        ),

        // ExpTech Studio 連結
        SegmentedList(
          label: Text('ExpTech Studio'),
          children: [
            SegmentedListTile(
              isFirst: true,
              leading: ContainedIcon(
                SimpleIcons.github,
                color: switch (context.theme.brightness) {
                  .light => SimpleIconColors.github,
                  .dark => SimpleIconColors.github.inverted,
                },
              ),
              title: const Text('Github'),
              subtitle: const Text('ExpTechTW'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => 'https://github.com/ExpTechTW/DPIP-Pocket'.launch(),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                SimpleIcons.discord,
                color: switch (context.theme.brightness) {
                  .light => .new(0xff454FBF),
                  .dark => .new(0xff5865F2),
                },
              ),
              title: const Text('Discord'),
              subtitle: const Text('.gg/exptech-studio'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => 'https://discord.gg/exptech-studio'.launch(),
              onLongPress: () => 'https://discord.gg/exptech-studio'.copy(),
            ),
            SegmentedListTile(
              leading: ContainedIcon(
                SimpleIcons.threads,
                color: switch (context.theme.brightness) {
                  .light => SimpleIconColors.threads,
                  .dark => SimpleIconColors.threads.inverted,
                },
              ),
              title: const Text('Threads'),
              subtitle: const Text('@dpip.tw'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => 'https://www.threads.net/@dpip.tw'.launch(),
              onLongPress: () => 'https://www.threads.net/@dpip.tw'.copy(),
            ),
            SegmentedListTile(
              isLast: true,
              leading: ContainedIcon(
                SimpleIcons.youtube,
                color: SimpleIconColors.youtube,
              ),
              title: const Text('Youtube'),
              subtitle: const Text('@exptechtw'),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () => 'https://www.youtube.com/@exptechtw/live'.launch(),
              onLongPress: () =>
                  'https://www.youtube.com/@exptechtw/live'.copy(),
            ),
          ],
        ),

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
              onTap: () =>
                  'https://apps.apple.com/tw/app/dpip/id6468026362'.launch(),
              onLongPress: () =>
                  'https://apps.apple.com/tw/app/dpip/id6468026362'.copy(),
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
                  'https://play.google.com/store/apps/details?id=com.exptech.dpip'
                      .launch(),
              onLongPress: () =>
                  'https://play.google.com/store/apps/details?id=com.exptech.dpip'
                      .copy(),
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
              isLast: true,
              leading: ContainedIcon(
                Symbols.bug_report_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              title: Text('App 日誌'.i18n),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => AppDebugLogsRoute().push(context),
            ),
          ],
        ),

        SegmentedList(
          children: [
            SegmentedListTile(
              isFirst: true,
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
