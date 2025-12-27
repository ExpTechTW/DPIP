import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

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
        Section(
          label: Text('HTTP 代理'.i18n),
          children: [
            SectionListTile(
              leading: Icon(Symbols.settings_ethernet_rounded),
              title: Text('啟用代理'.i18n),
              subtitle: Text('透過代理伺服器發送所有網路請求'.i18n),
              trailing: Switch(
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                  _saveSettings();
                },
              ),
            ),
            if (_enabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '代理主機'.i18n,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        hintText: 'localhost',
                        prefixIcon: const Icon(Symbols.dns_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerHighest,
                      ),
                      onChanged: (_) => _saveSettings(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '代理端口'.i18n,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        hintText: '9090',
                        prefixIcon: const Icon(Symbols.numbers_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerHighest,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _saveSettings(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.info_rounded,
                        color: context.colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '設定儲存後，需要重新啟動應用程式才能生效'.i18n,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
