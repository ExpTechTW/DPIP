import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsProxyPage extends StatefulWidget {
  const SettingsProxyPage({super.key});

  static const route = '/settings/proxy';

  @override
  State<SettingsProxyPage> createState() => _SettingsProxyPageState();
}

class _SettingsProxyPageState extends State<SettingsProxyPage> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = Preference.proxyEnabled ?? false;
    _hostController = TextEditingController(
      text: Preference.proxyHost ?? 'localhost',
    );
    _portController = TextEditingController(
      text: Preference.proxyPort?.toString() ?? '9090',
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    Preference.proxyEnabled = _enabled;
    Preference.proxyHost = _hostController.text.trim().isEmpty
        ? null
        : _hostController.text.trim();
    final portText = _portController.text.trim();
    Preference.proxyPort = portText.isEmpty ? null : int.tryParse(portText);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定已儲存'.i18n),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        SegmentedList(
          label: Text('HTTP 代理'.i18n),
          children: [
            SegmentedListTile(
              isFirst: true,
              isLast: !_enabled,
              leading: Icon(Symbols.settings_ethernet_rounded),
              title: Text('啟用代理'.i18n),
              subtitle: Text('透過代理伺服器發送所有網路請求'.i18n),
              trailing: Switch(
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                  _saveSettings();
                },
              ),
            ),
            if (_enabled) ...[
              SegmentedListTile(
                leading: Icon(Symbols.host_rounded),
                title: Text('代理主機'.i18n),
                content: TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    hintText: 'localhost',
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    visualDensity: .compact,
                  ),
                  onChanged: (_) => _saveSettings(),
                ),
              ),
              SegmentedListTile(
                isLast: true,
                leading: Icon(Symbols.settings_ethernet_rounded),
                title: Text('代理端口'.i18n),
                content: TextField(
                  controller: _portController,
                  decoration: InputDecoration(
                    hintText: '9090',
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    visualDensity: .compact,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _saveSettings(),
                ),
              ),
            ],
          ],
        ),
        if (_enabled) SectionText(child: Text('設定儲存後，需要重新啟動應用程式才能生效'.i18n)),
      ],
    );
  }
}
