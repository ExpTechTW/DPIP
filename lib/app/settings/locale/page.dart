/// Locale settings page for adjusting the app display language.
library;

import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// A settings page for selecting the app display language.
///
/// Shows the current locale and a link to open the locale selection page.
/// Requires [SettingsUserInterfaceModel] in the widget tree.
class SettingsLocalePage extends StatelessWidget {
  /// Creates a [SettingsLocalePage].
  const SettingsLocalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          padding: .only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            SettingsHeader(
              icon: Symbols.translate_rounded,
              title: Text('語言'.i18n),
              subtitle: Text('調整 DPIP 的顯示語言'.i18n),
            ),
            const SizedBox(height: 16),
            SegmentedList(
              children: [
                SegmentedListTile(
                  isFirst: true,
                  leading: ContainedIcon(
                    Symbols.translate_rounded,
                    color: Colors.blueAccent,
                  ),
                  title: Text('顯示語言'.i18n),
                  subtitle: Text(model.locale?.nativeName ?? '系統語言'.i18n),
                  trailing: Icon(Symbols.chevron_right_rounded),
                  onTap: () => const SettingsLocaleSelectRoute().push(context),
                ),
                SegmentedListTile(
                  isLast: true,
                  leading: ContainedIcon(
                    Symbols.groups_rounded,
                    color: Colors.greenAccent,
                  ),
                  title: Text('協助翻譯'.i18n),
                  subtitle: Text('點擊這裡來幫助我們改進 DPIP 的翻譯'.i18n),
                  trailing: Icon(Symbols.arrow_outward_rounded),
                  onTap: () => 'https://crowdin.com/project/dpip'.launch(),
                  onLongPress: () =>
                      'https://crowdin.com/project/dpip'.copy(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
