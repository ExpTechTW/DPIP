import 'package:dpip/app/settings/notify/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

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
      BasicNotifyType.all: (title: '接收全部'.i18n, icon: Symbols.notifications_rounded),
      BasicNotifyType.off: (title: '關閉'.i18n, icon: Symbols.notifications_off_rounded),
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
