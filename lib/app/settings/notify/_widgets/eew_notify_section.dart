import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class EewNotifySection extends StatefulWidget {
  final EewNotifyType value;
  final Future Function(EewNotifyType value) onChanged;

  const EewNotifySection({
    super.key,
    required this.value,
    required this.onChanged,
  });

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
      EewNotifyType.all: (
        title: '接收全部'.i18n,
        icon: Symbols.notification_add_rounded,
      ),
      EewNotifyType.localIntensityAbove1: (
        title: '所在地震度1以上'.i18n,
        icon: Symbols.notifications_rounded,
      ),
      EewNotifyType.localIntensityAbove4: (
        title: '所在地震度4以上'.i18n,
        icon: Symbols.notification_important_rounded,
      ),
    };

    return SegmentedList(
      label: Text('接收類別'.i18n),
      children: [
        for (final MapEntry(key: item, value: (:title, :icon))
            in values.entries)
          SegmentedListTile(
            leading: Icon(icon),
            title: Text(title),
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
