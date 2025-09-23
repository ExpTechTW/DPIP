import 'package:dpip/app/welcome/4-location/_widgets/location_select.dart';
import 'package:dpip/app/welcome/4-permissions/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class WelcomeLocationPage extends StatelessWidget {
  const WelcomeLocationPage({super.key});

  static const route = '/welcome/location';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(child: Text('下一步'.i18n), onPressed: () => context.push(WelcomePermissionPage.route)),
        ),
      ),
      body: SingleChildScrollView(
        padding: context.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '所在地'.i18n,
                      style: context.theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Selector<SettingsLocationModel, bool>(
                selector: (context, model) => model.auto,
                builder: (context, value, child) {
                  return RadioGroup<bool>(
                    groupValue: value,
                    onChanged: (value) {
                      if (value == null) return;

                      context.read<SettingsLocationModel>().setAuto(value);
                    },
                    child: Column(
                      spacing: 12,
                      children: [
                        Material(
                          color: value == true ? context.colors.primaryContainer : context.colors.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(value == true ? 24 : 12),
                            side: BorderSide(
                              width: 2,
                              color: value == true ? context.colors.onPrimaryContainer : context.colors.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: RadioListTile(
                            value: true,
                            controlAffinity: ListTileControlAffinity.trailing,
                            secondary: const Icon(Symbols.edit_rounded),
                            visualDensity: VisualDensity.comfortable,
                            tileColor: Colors.transparent,
                            activeColor: context.colors.onPrimaryContainer,
                            contentPadding: const EdgeInsets.only(left: 16, right: 8),
                            selected: value == true,
                            title: Text(
                              '自動更新'.i18n,
                              style: TextStyle(fontWeight: value == true ? FontWeight.bold : FontWeight.normal),
                            ),
                            subtitle: Text('使用裝置上的 GPS 定位功能，定期更新目前的所在地'.i18n),
                          ),
                        ),
                        Material(
                          color: value == false ? context.colors.primaryContainer : context.colors.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(value == false ? 24 : 12),
                            side: BorderSide(
                              width: 2,
                              color: value == false ? context.colors.onPrimaryContainer : context.colors.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Layout.col.stretch(
                            children: [
                              RadioListTile(
                                value: false,
                                controlAffinity: ListTileControlAffinity.trailing,
                                secondary: const Icon(Symbols.edit_rounded),
                                visualDensity: VisualDensity.comfortable,
                                tileColor: Colors.transparent,
                                activeColor: context.colors.onPrimaryContainer,
                                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                                selected: value == false,
                                title: Text(
                                  '手動設定'.i18n,
                                  style: TextStyle(fontWeight: value == false ? FontWeight.bold : FontWeight.normal),
                                ),
                                subtitle: '手動設定目前的所在地'.i18n.asText,
                              ),
                              Visibility(
                                visible: value == false,
                                maintainAnimation: true,
                                maintainState: true,
                                child: const LocationSelect(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
