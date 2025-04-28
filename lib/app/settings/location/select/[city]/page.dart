import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsLocationSelectCityPage extends StatelessWidget {
  final String city;

  const SettingsLocationSelectCityPage({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final towns = Global.location.entries.where((e) => e.value.city == city).toList();

    return ListView(
      children: [
        SettingsListSection(
          title: city,
          children: [
            for (final town in towns)
              Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder:
                    (context, code, child) => SettingsListTile(
                      title: '${town.value.city} ${town.value.town}',
                      subtitle: Text(
                        '${town.key}・${town.value.lng.toStringAsFixed(2)}°E・${town.value.lat.toStringAsFixed(2)}°N',
                      ),
                      trailing: Icon(code == town.key ? Symbols.check_rounded : null),
                      onTap: () {
                        context.pop();
                        context.pop();
                        context.read<SettingsLocationModel>().setCode(town.key);
                      },
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
