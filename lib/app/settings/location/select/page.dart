import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

class SettingsLocationSelectPage extends StatelessWidget {
  const SettingsLocationSelectPage({super.key});

  static const route = '/settings/location/select';

  @override
  Widget build(BuildContext context) {
    final entries = Global.location.entries.toList();

    final Set<String> walked = {};
    final locations = entries
        .where((e) => walked.add(e.key))
        .map((e) => e.value);

    final length = locations.length;

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        Section(
          label: Text('縣市'.i18n),
          children: [
            for (final (index, location) in locations.indexed)
              Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder: (context, currentCode, child) => SectionListTile(
                  isFirst: index == 0,
                  isLast: index == length - 1,
                  title: Text(location.cityWithLevel),
                  subtitle:
                      currentCode != null &&
                          location.cityWithLevel ==
                              currentCode.getLocation().cityWithLevel
                      ? Text('目前所在地'.i18n)
                      : null,
                  trailing: const Icon(Symbols.chevron_right_rounded),
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
