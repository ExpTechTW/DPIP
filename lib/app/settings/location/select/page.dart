import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsLocationSelectPage extends StatelessWidget {
  const SettingsLocationSelectPage({super.key});

  static const route = '/settings/location/select';

  @override
  Widget build(BuildContext context) {
    final entries = Global.location.entries;

    final Set<String> walked = {};
    final locations = entries
        .where((e) => walked.add(e.value.cityWithLevel))
        .map((e) => e.value)
        .toList();

    final length = locations.length;
    print('length = ${locations.length}');
    print(locations);

    final code = context.useLocation.code;

    return CustomScrollView(
      slivers: [
        SliverSegmentedList(
          label: Text('縣市'.i18n),
          children: [
            for (final (index, location) in locations.indexed)
              SegmentedListTile(
                isFirst: index == 0,
                isLast: index == length - 1,
                title: Text(location.cityWithLevel),
                subtitle:
                    code != null &&
                        location.cityWithLevel ==
                            code.getLocation().cityWithLevel
                    ? Text('目前所在地'.i18n)
                    : null,
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () => context.push(
                  '/settings/location/select/${location.cityWithLevel}',
                ),
              ),
          ],
        ),
        SliverPadding(padding: .only(bottom: context.padding.bottom + 16)),
      ],
    );
  }
}
