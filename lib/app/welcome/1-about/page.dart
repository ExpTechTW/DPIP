import 'package:dpip/core/i18n.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class WelcomeAboutPage extends StatelessWidget {
  const WelcomeAboutPage({super.key});

  static const route = '/welcome/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            child: Text('下一步'.i18n),
            onPressed: () => WelcomeExptechRoute().push(context),
          ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/DPIP.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '歡迎使用 DPIP'.i18n,
                      style: context.theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          'Disaster Prevention Information Platform',
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '防災資訊平台'.i18n,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'DPIP 是一款由臺灣本土團隊設計的 App，整合 TREM-Net (臺灣即時地震觀測網) 之資訊，以及中央氣象署資料，提供一個整合、單一且便利的防災資訊應用程式。'
                      .i18n,
                  style: context.theme.textTheme.bodyLarge,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
