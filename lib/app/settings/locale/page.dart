import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsLocalePage extends StatelessWidget {
  const SettingsLocalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            SegmentedList(
              children: [
                SegmentedListTile(
                  isFirst: true,
                  leading: ContainedIcon(
                    Symbols.translate_rounded,
                    color: Colors.blueAccent,
                  ),
                  title: Text('顯示語言'.i18n),
                  subtitle: Text(model.locale?.nativeName ?? '系統語言'.i18n),
                  trailing: Icon(Symbols.chevron_right_rounded),
                  onTap: () => const SettingsLocaleSelectRoute().push(context),
                ),
                SegmentedListTile(
                  isLast: true,
                  leading: ContainedIcon(
                    Symbols.groups_rounded,
                    color: Colors.greenAccent,
                  ),
                  title: Text('協助翻譯'.i18n),
                  subtitle: Text('點擊這裡來幫助我們改進 DPIP 的翻譯'.i18n),
                  trailing: Icon(Symbols.arrow_outward_rounded),
                  onTap: () => 'https://crowdin.com/project/dpip'.launch(),
                  onLongPress: () => 'https://crowdin.com/project/dpip'.copy(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Symbols.translate_rounded,
              color: context.colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '語言設定'.i18n,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '選擇應用程式的顯示語言'.i18n,
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
