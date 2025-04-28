import "package:collection/collection.dart";
import "package:dpip/api/model/crowdin/localization_progress.dart";
import "package:dpip/app/settings/_widgets/list_section.dart";
import "package:dpip/app/settings/_widgets/list_tile.dart";
import "package:dpip/global.dart";
import "package:dpip/l10n/app_localizations.dart";
import "package:dpip/models/settings/ui.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/extensions/color_scheme.dart";
import "package:dpip/utils/extensions/locale.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:provider/provider.dart";

class SettingsLocaleSelectPage extends StatefulWidget {
  const SettingsLocaleSelectPage({super.key});

  static const route = '/settings/locale/select';

  @override
  State<StatefulWidget> createState() => _SettingsLocaleSelectPageState();
}

class _SettingsLocaleSelectPageState extends State<SettingsLocaleSelectPage> {
  List<CrowdinLocalizationProgress> progress = [];
  List<Locale> localeList =
      AppLocalizations.supportedLocales.where((e) => !["zh"].contains(e.toLanguageTag())).toList();

  @override
  void initState() {
    super.initState();
    Global.api.getLocalizationProgress().then((value) {
      setState(() => progress = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingsListSection(
          title: '選擇語言',
          children: [
            for (final locale in localeList)
              Consumer<SettingsUserInterfaceModel>(
                builder: (context, model, child) {
                  final p = progress.firstWhereOrNull((e) => e.id == locale.toLanguageTag());

                  final translated = p != null ? NumberFormat("#.#%").format(p.translation / 100) : "...";
                  final approved = p != null ? NumberFormat("#.#%").format(p.approval / 100) : "...";

                  return SettingsListTile(
                    title: locale.nativeName,
                    subtitle:
                        (locale.toLanguageTag() != "zh-TW")
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${context.i18n.settings_locale_translated(translated)}・${context.i18n.settings_locale_approved(approved)}',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child:
                                      p != null
                                          ? Stack(
                                            children: [
                                              LinearProgressIndicator(
                                                value: p.translation / 100,
                                                borderRadius: BorderRadius.circular(8),
                                                color: context.theme.extendedColors.blue,
                                                backgroundColor: context.colors.outlineVariant,
                                              ),
                                              LinearProgressIndicator(
                                                value: p.approval / 100,
                                                borderRadius: BorderRadius.circular(8),
                                                color: context.theme.extendedColors.green,
                                                backgroundColor: Colors.transparent,
                                              ),
                                            ],
                                          )
                                          : const LinearProgressIndicator(),
                                ),
                              ],
                            )
                            : Text(context.i18n.source_language),
                    leading: locale.flag,
                    trailing: Icon(locale == model.locale ? Symbols.check_rounded : null),
                    onTap: () {
                      model.setLocale(locale);
                      context.pop();
                    },
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
