import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/models/settings/notify.dart';

class WeatherNotifySection extends StatefulWidget {
  final WeatherNotifyType value;
  final Future Function(WeatherNotifyType value) onChanged;

  const WeatherNotifySection({super.key, required this.value, required this.onChanged});

  @override
  State<WeatherNotifySection> createState() => _WeatherNotifySectionState();
}

class _WeatherNotifySectionState extends State<WeatherNotifySection> {
  WeatherNotifyType? _loading;

  Future onChanged(WeatherNotifyType value) async {
    setState(() => _loading = value);
    await setWeatherNotifyType(context, value, widget.onChanged);
    setState(() => _loading = null);
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      WeatherNotifyType.local: (title: '接收所在地', icon: Symbols.notifications_rounded),
      WeatherNotifyType.off: (title: '關閉', icon: Symbols.notifications_off_rounded),
    };

    return SettingsListSection(
      title: '接收類別',
      children: [
        for (final MapEntry(key: item, value: (:title, :icon)) in values.entries)
          SettingsListTile(
            title: title,
            icon: icon,
            trailing:
                _loading == item
                    ? loading
                    : (widget.value == item)
                    ? check
                    : empty,
            enabled: _loading == null,
            onTap: _loading == null ? () => onChanged(item) : null,
          ),
      ],
    );
  }
}
