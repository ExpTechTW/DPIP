import "package:dpip/global.dart";
import "package:dpip/route/locale_selector/locale_selector.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/extension/locale.dart";
import "package:dpip/util/extension/string.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:url_launcher/url_launcher.dart";

class SettingsLocaleView extends StatefulWidget {
  const SettingsLocaleView({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsLocaleViewState();
}

class _SettingsLocaleViewState extends State<SettingsLocaleView> {
  late Locale locale = Localizations.localeOf(context);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          ListTile(
            leading: const Icon(Symbols.translate),
            title: Text(context.i18n.settings_display_locale),
            subtitle: Text(locale.nativeName),
            onTap: () async {
              await Navigator.of(
                context,
                rootNavigator: true,
              ).push(
                MaterialPageRoute(
                  builder: (context) => LocaleSelectorRoute(locale),
                ),
              );

              setState(() {
                locale = Global.preference.getString("locale")?.asLocale ?? Localizations.localeOf(context);
              });
            },
          ),
          ListTile(
            leading: const Icon(Symbols.groups),
            title: Text(context.i18n.settings_locale_crowdin),
            subtitle: Text(context.i18n.settings_locale_crowdin_description),
            trailing: const Icon(Symbols.open_in_new),
            onTap: () {
              launchUrl(Uri.parse("https://crowdin.com/project/dpip"));
            },
          ),
        ],
      ),
    );
  }
}
