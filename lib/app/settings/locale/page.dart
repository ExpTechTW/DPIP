import 'package:dpip/core/i18n.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/app/settings/locale/select/page.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';

class SettingsLocalePage extends StatelessWidget {
  const SettingsLocalePage({super.key});

  static const route = '/settings/locale';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '語言'.i18n,
          children: [
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return ListSectionTile(
                  icon: Symbols.translate_rounded,
                  title: '顯示語言'.i18n,
                  subtitle: Text(model.locale?.nativeName ?? '系統語言'.i18n),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  onTap: () => context.push(SettingsLocaleSelectPage.route),
                );
              },
            ),
            ListSectionTile(
              icon: Symbols.groups_rounded,
              title: '協助翻譯'.i18n,
              subtitle: Text('點擊這裡來幫助我們改進 DPIP 的翻譯'.i18n),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () {
                launchUrl(Uri.parse('https://crowdin.com/project/dpip'));
              },
            ),
          ],
        ),
      ],
    );
  }
}
