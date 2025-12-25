import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsLocationSelectPage extends StatelessWidget {
  const SettingsLocationSelectPage({super.key});

  static const route = '/settings/location/select';

  @override
  Widget build(BuildContext context) {
    final entries = Global.location.entries.toList();

    final locations = entries
        .whereIndexed(
          (index, e) =>
              index ==
              entries.indexWhere(
                (v) =>
                    (v.value.city == e.value.city) &&
                    (v.value.cityLevel == e.value.cityLevel),
              ),
        )
        .toList();

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '縣市'.i18n,
          children: [
            for (final MapEntry(key: _, value: location) in locations)
              Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder: (context, currentCode, child) => ListSectionTile(
                  title: location.cityWithLevel,
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  subtitle:
                      currentCode != null &&
                          location.cityWithLevel ==
                              currentCode.getLocation().cityWithLevel
                      ? Text('目前所在地'.i18n)
                      : null,
                  onTap: () => context.push(
                    '/settings/location/select/${location.cityWithLevel}',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
