import 'package:dpip/app/settings/locale/select/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/locale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLocalePage extends StatelessWidget {
  const SettingsLocalePage({super.key});

  static const route = '/settings/locale';

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
            _buildLanguageCard(context, model),
            _buildTranslateCard(context),
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

  Widget _buildLanguageCard(
    BuildContext context,
    SettingsUserInterfaceModel model,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(SettingsLocaleSelectPage.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.language_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '顯示語言'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.locale?.nativeName ?? '系統語言'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranslateCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => launchUrl(Uri.parse('https://crowdin.com/project/dpip')),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.groups_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '協助翻譯'.i18n,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '點擊這裡來幫助我們改進 DPIP 的翻譯'.i18n,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.arrow_outward_rounded,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
