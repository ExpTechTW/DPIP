import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
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
