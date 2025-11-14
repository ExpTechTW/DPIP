import 'dart:collection';

import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsLocationSelectCityPage extends StatefulWidget {
  final String city;

  const SettingsLocationSelectCityPage({super.key, required this.city});

  static String route([String city = ':city']) => '/settings/location/select/$city';

  @override
  State<SettingsLocationSelectCityPage> createState() => _SettingsLocationSelectCityPageState();
}

class _SettingsLocationSelectCityPageState extends State<SettingsLocationSelectCityPage> {
  @override
  Widget build(BuildContext context) {
    final towns = Global.location.entries.where((e) => e.value.cityWithLevel == widget.city).toList();

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: widget.city,
          children: [
            for (final MapEntry(key: code, value: town) in towns)
              Selector<SettingsLocationModel, UnmodifiableSetView<String>>(
                selector: (context, model) => model.favorited,
                builder: (context, favorited, child) {
                  final isFavorited = favorited.contains(code);

                  return ListSectionTile(
                    title: town.cityTownWithLevel,
                    subtitle: Text('$code・${town.lng.toStringAsFixed(2)}°E・${town.lat.toStringAsFixed(2)}°N'),
                    trailing: isFavorited ? const Icon(Symbols.star_rounded, fill: 1) : null,
                    onTap: isFavorited
                        ? null
                        : () {
                            context.read<SettingsLocationModel>().favorite(code);
                            context.popUntil(SettingsLocationPage.route);
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
