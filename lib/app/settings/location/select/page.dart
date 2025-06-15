import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/list.dart';

final cities = Global.location.entries.map((e) => e.value.city).toSet().toList();

class SettingsLocationSelectPage extends StatelessWidget {
  const SettingsLocationSelectPage({super.key});

  static const route = '/settings/location/select';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '縣市'.i18n,
          children: [
            for (final city in cities)
              Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder:
                    (context, code, child) => ListSectionTile(
                      title: city,
                      trailing: const Icon(Symbols.chevron_right_rounded),
                      subtitle:
                          code != null &&
                                  Global.location.entries.containsWhere((e) => e.value.city == city && e.key == code)
                              ? Text('目前所在地'.i18n)
                              : null,
                      onTap: () => context.push('/settings/location/select/$city'),
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
