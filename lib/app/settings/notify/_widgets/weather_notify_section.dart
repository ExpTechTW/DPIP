import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      WeatherNotifyType.local: (title: '接收所在地'.i18n, icon: Symbols.notifications_rounded),
      WeatherNotifyType.off: (title: '關閉'.i18n, icon: Symbols.notifications_off_rounded),
    };

    return ListSection(
      title: '接收類別'.i18n,
      children: [
        for (final MapEntry(key: item, value: (:title, :icon)) in values.entries)
          ListSectionTile(
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
