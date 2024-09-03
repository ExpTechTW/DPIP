import "package:dpip/util/extension/build_context.dart";
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DPIPInfoPage extends StatelessWidget {
  const DPIPInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.me_developer),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.theme.colorScheme.primary.withOpacity(0.05),
              context.theme.colorScheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 24),
            _buildInfoCard(
                context,
                context.i18n.introduction,
                [
                  context.i18n.first_gratitude,
                  context.i18n.dpip_goal,
                  context.i18n.development_investment
                ],
                Symbols.info_rounded),
            _buildInfoCard(
                context,
                context.i18n.profit_model,
                [
                  context.i18n.profit_discussion
                ],
                Symbols.monetization_on_rounded),
            _buildInfoCard(
                context,
                context.i18n.profit_difficulty,
                [
                  context.i18n.user_payment_survey
                ],
                Symbols.trending_down_rounded),
            _buildInfoCard(
                context,
                context.i18n.why_no_ads,
                [
                  context.i18n.no_ads_reason
                ],
                Symbols.block_rounded),
            _buildInfoCard(
                context,
                context.i18n.charge_public,
                [
                  context.i18n.no_fee_reason,
                  context.i18n.public_charge_consideration
                ],
                Symbols.attach_money_rounded),
            _buildInfoCard(
                context,
                context.i18n.how_to_profit,
                [context.i18n.summary, '2024/08/28   YuYu1015', '©2024 ExpTech Studio Ltd.'],
                Symbols.lightbulb_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset(
              'assets/DPIP.png', // 替換為實際的 DPIP logo 資源路徑
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 16),
            Text(
              context.i18n.developer_message,
              style: context.theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<String> paragraphs, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: context.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...paragraphs
                .map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        paragraph,
                        style: context.theme.textTheme.bodyLarge,
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
