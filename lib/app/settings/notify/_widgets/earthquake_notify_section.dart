import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class EarthquakeNotifySection extends StatefulWidget {
  final EarthquakeNotifyType value;
  final Future Function(EarthquakeNotifyType value) onChanged;

  const EarthquakeNotifySection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<EarthquakeNotifySection> createState() =>
      _EarthquakeNotifySectionState();
}

class _EarthquakeNotifySectionState extends State<EarthquakeNotifySection> {
  EarthquakeNotifyType? _loading;

  Future onChanged(EarthquakeNotifyType value) async {
    setState(() => _loading = value);
    await setEarthquakeNotifyType(context, value, widget.onChanged);
    setState(() => _loading = null);
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      EarthquakeNotifyType.all: (
        title: '接收全部'.i18n,
        icon: Symbols.notification_add_rounded,
      ),
      EarthquakeNotifyType.localIntensityAbove1: (
        title: '所在地震度1以上'.i18n,
        icon: Symbols.notifications_rounded,
      ),
      EarthquakeNotifyType.off: (
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
