import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
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

    return ListSection(
      title: '接收類別'.i18n,
      children: [
        for (final MapEntry(key: item, value: (:title, :icon))
            in values.entries)
          ListSectionTile(
            title: title,
            icon: icon,
            trailing: _loading == item
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
