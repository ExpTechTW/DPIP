import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class SettingsLocationSelectCityPage extends StatefulWidget {
  final String city;

  const SettingsLocationSelectCityPage({super.key, required this.city});

  static String route([String city = ':city']) => '/settings/location/select/$city';

  @override
  State<SettingsLocationSelectCityPage> createState() => _SettingsLocationSelectCityPageState();
}

class _SettingsLocationSelectCityPageState extends State<SettingsLocationSelectCityPage> {
  String? loadingTown;

  @override
  Widget build(BuildContext context) {
    final towns = Global.location.entries.where((e) => e.value.city == widget.city).toList();

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: widget.city,
          children: [
            for (final town in towns)
              Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder:
                    (context, code, child) => ListSectionTile(
                      title: '${town.value.city} ${town.value.town}',
                      subtitle: Text(
                        '${town.key}・${town.value.lng.toStringAsFixed(2)}°E・${town.value.lat.toStringAsFixed(2)}°N',
                      ),
                      trailing:
                          loadingTown == town.key
                              ? const LoadingIcon()
                              : Icon(code == town.key ? Symbols.check_rounded : null),
                      enabled: loadingTown == null,
                      onTap: () async {
                        if (loadingTown != null) return;

                        setState(() => loadingTown = town.key);
                        await ExpTech().updateDeviceLocation(
                          token: Preference.notifyToken,
                          lat: town.value.lat.toString(),
                          lng: town.value.lng.toString(),
                        );

                        if (!context.mounted) return;
                        setState(() => loadingTown = null);

                        context.read<SettingsLocationModel>().setCode(town.key);
                        context.read<SettingsLocationModel>().setLatLng(
                          latitude: town.value.lat,
                          longitude: town.value.lng,
                        );
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
