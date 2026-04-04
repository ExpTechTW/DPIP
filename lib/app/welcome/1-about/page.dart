/// The first welcome step, introducing the DPIP app.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// Displays the "About DPIP" introduction page in the welcome flow.
///
/// Tapping the next button navigates to [WelcomeExptechRoute].
class WelcomeAboutPage extends StatelessWidget {
  /// Creates a [WelcomeAboutPage].
  const WelcomeAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            child: Text('下一步'.i18n),
            onPressed: () => WelcomeExptechRoute().push(context),
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
                    child: ClipRRect(
                      borderRadius: .circular(16),
                      child: Image.asset(
                        'assets/DPIP.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const .all(16),
                    child: Text(
                      '歡迎使用 DPIP'.i18n,
                      style: context.texts.headlineMedium?.copyWith(
                        fontWeight: .bold,
                        color: context.colors.primary,
                      ),
                      textAlign: .center,
                    ),
                  ),
                  Padding(
                    padding: const .all(8),
                    child: Column(
                      children: [
                        Text(
                          'Disaster Prevention Information Platform',
                          style: context.texts.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: .center,
                        ),
                        Text(
                          '防災資訊平台'.i18n,
                          style: context.texts.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: .center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const .all(16),
              child: Container(
                padding: const .all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: .circular(16),
                ),
                child: Text(
                  'DPIP 是一款由臺灣本土團隊設計的 App，整合 TREM-Net (臺灣即時地震觀測網) 之資訊，以及中央氣象署資料，提供一個整合、單一且便利的防災資訊應用程式。'
                      .i18n,
                  style: context.texts.bodyLarge,
                  textAlign: .left,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
