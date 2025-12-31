import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class TsunamiNotifySection extends StatefulWidget {
  final TsunamiNotifyType value;
  final Future Function(TsunamiNotifyType value) onChanged;

  const TsunamiNotifySection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TsunamiNotifySection> createState() => _TsunamiNotifySectionState();
}

class _TsunamiNotifySectionState extends State<TsunamiNotifySection> {
  TsunamiNotifyType? _loading;

  Future onChanged(TsunamiNotifyType value) async {
    setState(() => _loading = value);
    await setTsunamiNotifyType(context, value, widget.onChanged);
    setState(() => _loading = null);
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      TsunamiNotifyType.all: (
        title: '海嘯消息、海嘯警報'.i18n,
        icon: Symbols.notifications_rounded,
      ),
      TsunamiNotifyType.warningOnly: (
        title: '只接收海嘯警報'.i18n,
        icon: Symbols.notification_important_rounded,
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
