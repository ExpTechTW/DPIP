/// The third welcome step, displaying important usage notices.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Displays legal and safety notices the user should read before using DPIP.
///
/// Tapping the next button navigates to [WelcomePermissionsRoute].
class WelcomeNoticePage extends StatelessWidget {
  /// Creates a [WelcomeNoticePage].
  const WelcomeNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            child: Text('下一步'.i18n),
            onPressed: () => WelcomePermissionsRoute().push(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: context.padding,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(0, 32, 0, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const .all(16),
                    child: Icon(
                      Symbols.warning_rounded,
                      size: 80,
                      color: context.colors.primary,
                      fill: 1,
                    ),
                  ),
                  Padding(
                    padding: const .all(16),
                    child: Text(
                      '注意事項'.i18n,
                      style: context.texts.headlineMedium?.copyWith(
                        fontWeight: .bold,
                        color: context.colors.primary,
                      ),
                      textAlign: .center,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.errorContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  '任何資訊應以中央氣象署發布之內容為準。'.i18n,
                  style: context.texts.bodyLarge!.copyWith(
                    color: context.colors.onErrorContainer,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  '根據網路狀態、伺服器狀態、應用程式狀態、上游資料來源狀態等，有收不到資訊的可能性，我們會盡力避免此類情況，但不保證一定不會發生。'.i18n,
                  style: context.texts.bodyLarge,
                ),
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  '強烈搖晃有機率比通知早抵達使用者所在地。'.i18n,
                  style: context.texts.bodyLarge,
                ),
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  '地震速報為快速計算之結果，可能存在較大誤差，應理解並謹慎使用。'.i18n,
                  style: context.texts.bodyLarge,
                ),
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  '任何不被官方所認可的行為均有可能承擔法律風險，請務必遵守相關規範。'.i18n,
                  style: context.texts.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
