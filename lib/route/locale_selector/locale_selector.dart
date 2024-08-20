import 'package:collection/collection.dart';
import 'package:dpip/global.dart';
import 'package:dpip/main.dart';
import 'package:dpip/model/crowdin/localization_progress.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:dpip/util/extension/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LocaleSelectorRoute extends StatefulWidget {
  final Locale locale;

  const LocaleSelectorRoute(this.locale, {super.key});

  @override
  State<StatefulWidget> createState() => _LocaleSelectorRouteState();
}

class _LocaleSelectorRouteState extends State<LocaleSelectorRoute> {
  List<CrowdinLocalizationProgress> progress = [];
  List<Locale> localeList = AppLocalizations.supportedLocales.where((e) => !["zh"].contains(e.toLanguageTag())).toList();

  @override
  void initState() {
    super.initState();
    Global.api.getLocalizationProgress().then((value) {
      setState(() => progress = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.settings_locale),
      ),
      body: ListView.builder(
        itemCount: localeList.length,
        itemBuilder: (context, index) {
          final locale = localeList[index];
          final p = progress.firstWhereOrNull(
            (e) => e.id == locale.toLanguageTag(),
          );

          final translated = p != null ? NumberFormat("#.#%").format(p.translation / 100) : "...";
          final approved = p != null ? NumberFormat("#.#%").format(p.approval / 100) : "...";

          return RadioListTile(
            title: Text(locale.nativeName),
            subtitle: (locale.toLanguageTag() != "zh-TW")
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.i18n.settings_locale_translated(translated)),
                      Text(context.i18n.settings_locale_approved(approved)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: p != null
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
            groupValue: widget.locale,
            onChanged: (value) async {
              DpipApp.of(context)!.changeLocale(value);
              if (value == null) {
                await Global.preference.remove("locale");
              } else {
                await Global.preference.setString("locale", value.toLanguageTag());
              }

              if (!context.mounted) return;

              Navigator.pop(context, value);
            },
          );
        },
      ),
    );
  }
}
