/// The support page: subscriptions and one-time tips via in-app purchase.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:dpip/features/sponsor/presentation/sponsor_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Presents ways to support DPIP. Products load from the store through
/// [SponsorController]; the shared async-state views cover loading / failure so
/// a store hiccup never blanks the screen.
class SponsorPage extends StatelessWidget {
  const SponsorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SponsorController>(
      create: (context) =>
          SponsorController(context.read<SponsorRepository>())..load(),
      child: const _SponsorView(),
    );
  }
}

class _SponsorView extends StatelessWidget {
  const _SponsorView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<SponsorController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sponsorTitle)),
      body: switch (controller.status) {
        SponsorStatus.loading => const LoadingView(),
        SponsorStatus.error => ErrorView(onRetry: controller.load),
        SponsorStatus.ready => RefreshIndicator(
          onRefresh: controller.load,
          child: _SponsorList(controller: controller),
        ),
      },
    );
  }
}

class _SponsorList extends StatelessWidget {
  const _SponsorList({required this.controller});

  final SponsorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const _Header(),
        if (controller.subscriptions.isNotEmpty) ...[
          _SectionTitle(title: l10n.sponsorSubscriptions, recommended: true),
          for (final product in controller.subscriptions)
            _ProductCard(controller: controller, product: product),
        ],
        if (controller.oneTime.isNotEmpty) ...[
          _SectionTitle(title: l10n.sponsorOneTime),
          for (final product in controller.oneTime)
            _ProductCard(controller: controller, product: product),
        ],
        const SizedBox(height: AppSpacing.sm),
        _Footer(controller: controller),
      ],
    );
  }
}

/// The hero intro card explaining what support funds.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.6),
            colors.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, size: 48, color: colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.sponsorTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.sponsorIntro,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading, optionally with a "recommended" chip.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.recommended = false});

  final String title;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!recommended) return SectionHeader(title);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: AppRadius.small,
            ),
            child: Text(
              l10n.sponsorRecommended,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One product row — icon, title, description, and a trailing price button that
/// becomes a spinner while buying and a check once owned.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.controller, required this.product});

  final SponsorController controller;
  final SponsorProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final purchasing = controller.purchasingId == product.id;
    final purchased = controller.purchasedIds.contains(product.id);
    final disabled = (controller.isBusy && !purchasing) || purchased;
    final sub = product.isSubscription;
    final priceText = sub ? l10n.sponsorPerMonth(product.price) : product.price;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: sub
            ? colors.tertiaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : () => controller.buy(product),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: sub
                    ? colors.tertiary
                    : colors.primaryContainer,
                foregroundColor: sub
                    ? colors.onTertiary
                    : colors.onPrimaryContainer,
                child: Icon(
                  sub ? Icons.workspace_premium : Icons.coffee_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Trailing(
                purchasing: purchasing,
                purchased: purchased,
                disabled: disabled,
                priceText: priceText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trailing slot of a product row: a check when owned, a spinner while
/// buying, otherwise a price pill.
class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.purchasing,
    required this.purchased,
    required this.disabled,
    required this.priceText,
  });

  final bool purchasing;
  final bool purchased;
  final bool disabled;
  final String priceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (purchased) {
      return Icon(Icons.check_circle, color: colors.primary);
    }
    if (purchasing) {
      return const InlineLoading(size: 20);
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: disabled ? colors.surfaceContainerHighest : colors.primary,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        priceText,
        style: theme.textTheme.labelLarge?.copyWith(
          color: disabled ? colors.onSurfaceVariant : colors.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Restore-purchases plus the legal links.
class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final SponsorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Divider(color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink(
                text: l10n.sponsorRestore,
                onTap: () => _restore(context),
              ),
              _FooterLink(
                text: l10n.sponsorTerms,
                onTap: () => _open('https://exptech.com.tw/tos'),
              ),
              _FooterLink(
                text: l10n.sponsorPrivacy,
                onTap: () => _open('https://exptech.com.tw/privacy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.restore();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.sponsorRestoring : l10n.sponsorRestoreUnavailable,
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'open sponsor link $url');
    }
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
