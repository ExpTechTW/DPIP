import 'package:dpip/app/welcome/4-location/page.dart';
import 'package:dpip/app/welcome/4-permissions/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class WelcomeNoticePage extends StatelessWidget {
  const WelcomeNoticePage({super.key});

  static const route = '/welcome/notice';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(child: Text('下一步'.i18n), onPressed: () => context.push(WelcomeLocationPage.route)),
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
                    child: Icon(Symbols.warning_rounded, size: 80, color: context.colors.primary, fill: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '注意事項'.i18n,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '任何資訊應以中央氣象署發布之內容為準。'.i18n,
                  style: context.theme.textTheme.bodyLarge!.copyWith(
                    color: context.colors.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '根據網路狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等，有收不到資訊的可能性，我們會盡力避免此類情況，但不保證一定不會發生。'.i18n,
                  style: context.theme.textTheme.bodyLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('強烈搖晃有機率比通知早抵達使用者所在地。'.i18n, style: context.theme.textTheme.bodyLarge),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('地震速報為快速計算之結果，可能存在較大誤差，應理解並謹慎使用。'.i18n, style: context.theme.textTheme.bodyLarge),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('任何不被官方所認可的行為均有可能承擔法律風險，請務必遵守相關規範。'.i18n, style: context.theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
