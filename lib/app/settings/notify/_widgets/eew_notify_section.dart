import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/models/settings/notify.dart';

class EewNotifySection extends StatefulWidget {
  final EewNotifyType value;
  final Future Function(EewNotifyType value) onChanged;

  const EewNotifySection({super.key, required this.value, required this.onChanged});

  @override
  State<EewNotifySection> createState() => _EewNotifySectionState();
}

class _EewNotifySectionState extends State<EewNotifySection> {
  EewNotifyType? _loading;

  Future onChanged(EewNotifyType value) async {
    setState(() => _loading = value);
    await setEewNotifyType(context, value, widget.onChanged);
    setState(() => _loading = null);
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      EewNotifyType.all: (title: '接收全部', icon: Symbols.notification_add_rounded),
      EewNotifyType.localIntensityAbove1: (title: '所在地震度1以上', icon: Symbols.notifications_rounded),
      EewNotifyType.localIntensityAbove4: (title: '所在地震度4以上', icon: Symbols.notification_important_rounded),
    };

    return ListSection(
      title: '接收類別',
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
