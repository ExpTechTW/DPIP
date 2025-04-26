import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLocalePage extends StatelessWidget {
  const SettingsLocalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
      children: [
        SettingsListSection(
          title: context.i18n.settings_locale,
          children: [
            Consumer<SettingsUserInterfaceModel>(
              builder: (context, model, child) {
                return SettingsListTile(
                  icon: Symbols.translate_rounded,
                  title: context.i18n.settings_display_locale,
                  subtitle: Text(model.locale?.nativeName ?? 'System Language'),
                  onTap: () => context.push('/settings/locale/select'),
                );
              },
            ),
            SettingsListTile(
              icon: Symbols.groups_rounded,
              title: context.i18n.settings_locale_crowdin,
              subtitle: Text(context.i18n.settings_locale_crowdin_description),
              trailing: const Icon(Symbols.arrow_outward_rounded),
              onTap: () {
                launchUrl(Uri.parse("https://crowdin.com/project/dpip"));
              },
            ),
          ],
        ),
      ],
    );
  }
}
