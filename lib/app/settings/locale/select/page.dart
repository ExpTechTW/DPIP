import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dpip/api/model/crowdin/localization_progress.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:option_result/result.dart';

class SettingsLocaleSelectPage extends StatefulWidget {
  const SettingsLocaleSelectPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsLocaleSelectPageState();
}

class _SettingsLocaleSelectPageState extends State<SettingsLocaleSelectPage>
    with TickerProviderStateMixin {
  late final _animationController =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )
        ..addListener(() {
          if (mounted) setState(() {});
        })
        ..repeat();

  Result<List<CrowdinLocalizationProgress>, String>? progress;
  List<Locale> localeList = I18n.supportedLocales
      .where((e) => !['zh'].contains(e.toLanguageTag()))
      .toList();

  Future<void> _refresh() async {
    final result = await Global.api.getLocalizationProgress();
    setState(() => progress = result);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.useUserInterface.locale;
    final data = switch (progress) {
      Ok(:final value)? => value,
      _ => null,
    };

    final phaseValue = _animationController.value * 2 * pi;

    final children = localeList.mapIndexed((index, item) {
      final p = data?.firstWhereOrNull(
        (e) => e.id == item.toLanguageTag(),
      );

      final translated = p != null
          ? NumberFormat('#.#%').format(p.translation / 100)
          : '...';
      final approved = p != null
          ? NumberFormat('#.#%').format(p.approval / 100)
          : '...';

      final isSelected = item.toLanguageTag() == locale?.toLanguageTag();

      final progressBar = IgnorePointer(
        child: SizedBox(
          height: 10,
          child: switch (p) {
            null => LinearProgressIndicatorM3E(
              size: .s,
              phase: phaseValue,
            ),
            _ => SliderTheme(
              data: SliderThemeData(
                thumbSize: .all(.zero),
                trackGap: 1,
                trackHeight: 5,
                padding: .zero,
                year2023: false,
              ),
              child: Slider(
                activeColor: context.theme.extendedColors.green,
                secondaryActiveColor: context.theme.extendedColors.blue,
                value: p.approval / 100,
                secondaryTrackValue: p.translation / 100,
                onChanged: (_) {},
              ),
            ),
          },
        ),
      );

      return SegmentedListTile(
        isFirst: index == 0,
        isLast: index == localeList.length - 1,
        title: Text(item.nativeName),
        subtitle: (item.toLanguageTag() != 'zh-Hant')
            ? Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    '已翻譯 {translated}・已校對 {approved}'.i18n.args({
                      'translated': translated,
                      'approved': approved,
                    }),
                  ),
                  RepaintBoundary(
                    child: Padding(
                      padding: const .symmetric(vertical: 4),
                      child: progressBar,
                    ),
                  ),
                ],
              )
            : Text('來源語言'.i18n),
        leading: Container(
          height: 28,
          width: 40,
          decoration: BoxDecoration(
            color: context.colors.secondaryContainer,
            borderRadius: .circular(6),
          ),
          child: Center(
            child: Text(
              item.iconLabel,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSecondaryContainer,
                height: 1,
              ),
            ),
          ),
        ),
        trailing: Icon(isSelected ? Symbols.check_rounded : null),
        onTap: () {
          context.locale = item;
          context.userInterface.setLocale(item);
          context.pop();
        },
      );
    }).toList();

    return ExpressiveRefreshIndicator.contained(
      onRefresh: _refresh,
      backgroundColor: context.colors.primaryContainer,
      child: ListView(
        padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
        children: [
          SegmentedList(
            label: Text('選擇語言'.i18n),
            children: children,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
