import 'package:dpip/app/welcome/3-notice/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeExpTechPage extends StatelessWidget {
  const WelcomeExpTechPage({super.key});

  static const route = '/welcome/exptech';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            child: Text('下一步'.i18n),
            onPressed: () => context.push(WelcomeNoticePage.route),
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
                        'assets/ExpTech.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ExpTech Studio',
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
                          '©2024 ExpTech Studio Ltd.',
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
                child: Column(
                  children: [
                    Text(
                      '我們是誰？'.i18n,
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ExpTech Studio 是一群大部分由學生組成，平均年齡未滿 20 歲、人數超過 15 + 的團體。成員來自臺灣北中南、日本、韓國、中國的學生。'
                          .i18n,
                      style: context.theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '我們的初衷'.i18n,
                      style: context.theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '成立初衷是招募一群對電腦及科技有興趣及能力的同學，後來發展至校外，並逐漸形成現在的樣子。'.i18n,
                      style: context.theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
