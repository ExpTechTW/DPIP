import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/model/crowdin/localization_progress.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';

class SettingsLocaleSelectPage extends StatefulWidget {
  const SettingsLocaleSelectPage({super.key});

  static const route = '/settings/locale/select';

  @override
  State<StatefulWidget> createState() => _SettingsLocaleSelectPageState();
}

class _SettingsLocaleSelectPageState extends State<SettingsLocaleSelectPage> {
  List<CrowdinLocalizationProgress> progress = [];
  List<Locale> localeList = I18n.supportedLocales.where((e) => !['zh'].contains(e.toLanguageTag())).toList();

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
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '選擇語言'.i18n,
          children: [
            for (final item in localeList)
              Selector<SettingsUserInterfaceModel, Locale?>(
                selector: (_, model) => model.locale,
                builder: (context, locale, child) {
                  final p = progress.firstWhereOrNull((e) => e.id == item.toLanguageTag());

                  final translated = p != null ? NumberFormat('#.#%').format(p.translation / 100) : '...';
                  final approved = p != null ? NumberFormat('#.#%').format(p.approval / 100) : '...';

                  final isSelected = item.toLanguageTag() == locale?.toLanguageTag();

                  return ListSectionTile(
                    title: item.nativeName,
                    subtitle:
                        (item.toLanguageTag() != 'zh-Hant')
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '已翻譯 {translated}・已校對 {approved}'.i18n.args({
                                    'translated': translated,
                                    'approved': approved,
                                  }),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child:
                                      p != null
                                          ? Stack(
                                            children: [
                                              LinearProgressIndicator(
                                                value: p.translation / 100,
                                                color: Colors.blue,
                                                year2023: false,
                                              ),
                                              LinearProgressIndicator(
                                                value: p.approval / 100,
                                                color: Colors.lightGreen,
                                                backgroundColor: Colors.transparent,
                                                year2023: false,
                                              ),
                                            ],
                                          )
                                          : const LinearProgressIndicator(year2023: false),
                                ),
                              ],
                            )
                            : Text('來源語言'.i18n),
                    leading: Container(
                      height: 28,
                      width: 40,
                      decoration: BoxDecoration(
                        color: context.colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          item.iconLabel,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colors.onSecondaryContainer,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    trailing: Icon(isSelected ? Symbols.check_rounded : null),
                    onTap: () {
                      context.locale = item;
                      context.read<SettingsUserInterfaceModel>().setLocale(item);
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
