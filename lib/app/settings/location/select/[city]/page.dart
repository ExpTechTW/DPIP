import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsLocationSelectCityPage extends StatelessWidget {
  final String city;

  const SettingsLocationSelectCityPage({super.key, required this.city});

  static String route([String city = ':city']) => '/settings/location/select/$city';

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
                      onTap: () async {
                        await ExpTech().updateDeviceLocation(
                          token: Preference.notifyToken,
                          lat: town.value.lat.toString(),
                          lng: town.value.lng.toString(),
                        );

                        if (!context.mounted) return;

                        context.read<SettingsLocationModel>().setCode(town.key);
                        context.read<SettingsLocationModel>().setLongitude(town.value.lng);
                        context.read<SettingsLocationModel>().setLatitude(town.value.lat);
                        context.popUntil(SettingsLocationPage.route);
                      },
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
