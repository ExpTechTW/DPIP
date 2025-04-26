import "package:collection/collection.dart";
import "package:dpip/api/model/crowdin/localization_progress.dart";
import "package:dpip/global.dart";
import "package:dpip/l10n/app_localizations.dart";
import "package:dpip/models/settings/ui.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/extensions/color_scheme.dart";
import "package:dpip/utils/extensions/locale.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

class SettingsLocaleSelectPage extends StatefulWidget {
  const SettingsLocaleSelectPage({super.key});

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
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView.builder(
          itemCount: localeList.length,
          itemBuilder: (context, index) {
            final locale = localeList[index];
            final p = progress.firstWhereOrNull((e) => e.id == locale.toLanguageTag());

            final translated = p != null ? NumberFormat("#.#%").format(p.translation / 100) : "...";
            final approved = p != null ? NumberFormat("#.#%").format(p.approval / 100) : "...";

            return RadioListTile(
              title: Text(locale.nativeName),
              subtitle:
                  (locale.toLanguageTag() != "zh-TW")
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.i18n.settings_locale_translated(translated)),
                          Text(context.i18n.settings_locale_approved(approved)),
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
              controlAffinity: ListTileControlAffinity.trailing,
              value: locale,
              groupValue: model.locale,
              onChanged: (value) {
                model.setLocale(value);
                Navigator.pop(context, value);
              },
            );
          },
        );
      },
    );
  }
}
