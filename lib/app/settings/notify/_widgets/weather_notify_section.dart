import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WeatherNotifySection extends StatefulWidget {
  final WeatherNotifyType value;
  final Future Function(WeatherNotifyType value) onChanged;

  const WeatherNotifySection({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
      WeatherNotifyType.local: (
        title: '接收所在地'.i18n,
        icon: Symbols.notifications_rounded,
      ),
      WeatherNotifyType.off: (
        title: '關閉'.i18n,
        icon: Symbols.notifications_off_rounded,
      ),
    };

    final entry = values.entries.toList();

    return SegmentedList(
      label: Text('接收類別'.i18n),
      children: [
        for (int i = 0; i < entry.length; i++)
          SegmentedListTile(
            leading: Icon(entry[i].value.icon),
            title: Text(entry[i].value.title),
            trailing: _loading == entry[i].key
                ? loading
                : (widget.value == entry[i].key)
                ? check
                : empty,
            enabled: _loading == null,
            onTap: _loading == null ? () => onChanged(entry[i].key) : null,
            isFirst: i == 0,
            isLast: i == entry.length - 1,
          ),
      ],
    );
  }
}
