import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/models/settings/notify.dart';

class BasicNotifySection extends StatefulWidget {
  final BasicNotifyType value;
  final Future Function(BasicNotifyType value) onChanged;

  const BasicNotifySection({super.key, required this.value, required this.onChanged});

  @override
  State<BasicNotifySection> createState() => _BasicNotifySectionState();
}

class _BasicNotifySectionState extends State<BasicNotifySection> {
  BasicNotifyType? _loading;

  Future onChanged(BasicNotifyType value) async {
    setState(() => _loading = value);
    await setBasicNotifyType(context, value, widget.onChanged);
    setState(() => _loading = null);
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      BasicNotifyType.all: (title: '接收全部', icon: Symbols.notifications_rounded),
      BasicNotifyType.off: (title: '關閉', icon: Symbols.notifications_off_rounded),
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
