import 'dart:io';
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/product_detail.dart';
import 'package:dpip/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDonatePage extends StatefulWidget {
  const SettingsDonatePage({super.key});

  static const route = '/settings/donate';

  @override
  State<SettingsDonatePage> createState() => _SettingsDonatePageState();
}

class _SettingsDonatePageState extends State<SettingsDonatePage>
    with SingleTickerProviderStateMixin {
  bool isPending = false;
  String? processingProductId;
  final Set<String> purchasedProductIds = {};

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  Completer<List<ProductDetails>> products = Completer();

  late AnimationController _shimmerController;

  final Set<String> _kIds = <String>{
    's_donation75',
    'donation100',
    'donation300',
    'donation1000',
  };
  StreamSubscription<List<PurchaseDetails>>? subscription;

  Future<void> refresh() async {
    setState(() {
      products = Completer<List<ProductDetails>>();
      purchasedProductIds.clear();
    });

    final isAvailable = await InAppPurchase.instance.isAvailable();

    if (!isAvailable) {
      products.completeError('無法連線至商店，請稍後再試'.i18n);
      return;
    }

    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      products.completeError('找不到商品，請稍候再試'.i18n);
      return;
    }

    products.complete(response.productDetails);
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshIndicatorKey.currentState?.show();
    });

    subscription?.cancel();
    subscription = InAppPurchase.instance.purchaseStream.listen(
      onPurchaseUpdate,
      onError: (error) {
        if (!mounted) return;
        setState(() => isPending = false);
      },
    );
    refresh();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    subscription?.cancel();
    super.dispose();
  }

  void onPurchaseUpdate(List<PurchaseDetails> list) {
    if (!mounted) return;

    final hasAnyPending =
    list.any((d) => d.status == PurchaseStatus.pending);

    setState(() {
      isPending = hasAnyPending;
      if (!hasAnyPending) processingProductId = null;
    });

    for (final d in list) {
      switch (d.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (d.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(d);
          }
          setState(() {
            purchasedProductIds.add(d.productID);
          });
          break;

        case PurchaseStatus.pending:
          if (processingProductId == null) {
            setState(() {
              processingProductId = d.productID;
            });
          }
          break;

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (d.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(d);
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: refresh,
      child: FutureBuilder(
        future: products.future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final error = snapshot.error;

          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Text(error.toString()),
                  FilledButton.tonal(
                    onPressed: refresh,
                    child: Text('重新載入'.i18n),
                  ),
                ],
              ),
            );
          }

          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  const CircularProgressIndicator(),
                  Text('正在載入商店物品中'.i18n),
                ],
              ),
            );
          }

          final subscriptions = data
              .where((item) => item.isSubscription)
              .sorted((a, b) => ascending(a.rawPrice, b.rawPrice));
          final oneTime = data
              .where((item) => !item.isSubscription)
              .sorted((a, b) => ascending(a.rawPrice, b.rawPrice));

          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              _buildHeader(),
              if (subscriptions.isNotEmpty) _buildSubscriptionSection(subscriptions),
              if (oneTime.isNotEmpty) _buildOneTimeSection(oneTime),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primaryContainer.withOpacity(0.5),
            context.colors.tertiaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.favorite_rounded,
            size: 48,
            color: context.colors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            '支持 DPIP'.i18n,
            style: context.texts.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DPIP 作為一款致力於提供即時地震資訊的 App，目前並無廣告或其他盈利模式。您的支持將幫助我們維持伺服器運行與持續開發。'
                .i18n,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(List<ProductDetails> subscriptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Symbols.workspace_premium_rounded,
                color: const Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '訂閱制'.i18n,
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '推薦'.i18n,
                  style: context.texts.labelSmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final product in subscriptions)
          _buildSubscriptionCard(product),
      ],
    );
  }

  Widget _buildSubscriptionCard(ProductDetails product) {
    final isDisabled =
        processingProductId != null && processingProductId != product.id;
    final isProcessing = processingProductId == product.id;
    final isPurchased = purchasedProductIds.contains(product.id);

    final title = product.title.contains('(')
        ? product.title.substring(0, product.title.indexOf('(')).trim()
        : product.title;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withOpacity(isDisabled ? 0.3 : 0.15),
                const Color(0xFFFFA500).withOpacity(isDisabled ? 0.3 : 0.15),
                const Color(0xFFFFD700).withOpacity(isDisabled ? 0.3 : 0.15),
              ],
              stops: [
                0.0,
                _shimmerController.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isPending || isPurchased
                  ? null
                  : () {
                      setState(() {
                        isPending = true;
                        processingProductId = product.id;
                      });
                      final purchaseParam = PurchaseParam(
                        productDetails: product,
                      );
                      InAppPurchase.instance.buyNonConsumable(
                        purchaseParam: purchaseParam,
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFD700).withOpacity(isDisabled ? 0.3 : 0.8),
                            const Color(0xFFFFA500).withOpacity(isDisabled ? 0.3 : 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Symbols.diamond_rounded,
                        color: isDisabled ? Colors.grey : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.texts.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDisabled
                                  ? context.theme.disabledColor
                                  : context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: context.texts.bodySmall?.copyWith(
                              color: isDisabled
                                  ? context.theme.disabledColor
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPurchased)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Symbols.check_rounded,
                          color: context.colors.onPrimary,
                          size: 20,
                        ),
                      )
                    else if (isProcessing)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: isDisabled
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                          color: isDisabled ? context.theme.disabledColor : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '{price}/月'.i18n.args({'price': product.price}),
                          style: context.texts.labelLarge?.copyWith(
                            color: isDisabled ? Colors.white54 : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOneTimeSection(List<ProductDetails> oneTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(
                Symbols.favorite_rounded,
                color: context.colors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '單次支援'.i18n,
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        for (final product in oneTime) _buildOneTimeCard(product),
      ],
    );
  }

  Widget _buildOneTimeCard(ProductDetails product) {
    final isDisabled =
        processingProductId != null && processingProductId != product.id;
    final isProcessing = processingProductId == product.id;

    final title = product.title.contains('(')
        ? product.title.substring(0, product.title.indexOf('(')).trim()
        : product.title;

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
          onTap: isPending
              ? null
              : () {
                  setState(() {
                    isPending = true;
                    processingProductId = product.id;
                  });
                  final purchaseParam = PurchaseParam(
                    productDetails: product,
                  );
                  InAppPurchase.instance.buyConsumable(
                    purchaseParam: purchaseParam,
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.coffee_rounded,
                    color: isDisabled
                        ? context.theme.disabledColor
                        : context.colors.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDisabled
                              ? context.theme.disabledColor
                              : context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: context.texts.bodySmall?.copyWith(
                          color: isDisabled
                              ? context.theme.disabledColor
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? context.theme.disabledColor
                          : context.colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.price,
                      style: context.texts.labelLarge?.copyWith(
                        color: isDisabled
                            ? Colors.white54
                            : context.colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Divider(color: context.colors.outlineVariant),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFooterLink(
                '恢復購買'.i18n,
                onTap: () async {
                  final bool available =
                      await InAppPurchase.instance.isAvailable();
                  if (!context.mounted) return;

                  if (!available) {
                    final storeName =
                        Platform.isIOS ? 'App Store' : 'Google Play';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '無法連線至 {store}，請稍後再試。'.i18n.args({
                            'store': storeName,
                          }),
                        ),
                      ),
                    );
                    return;
                  }
                  InAppPurchase.instance.restorePurchases();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('正在恢復您購買的訂閱'.i18n)),
                  );
                },
              ),
              _buildFooterLink(
                '使用條款'.i18n,
                onTap: () => launchUrl(Uri.parse('https://exptech.dev/tos')),
              ),
              _buildFooterLink(
                '隱私權政策'.i18n,
                onTap: () => launchUrl(Uri.parse('https://exptech.dev/privacy')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.primary,
            decoration: TextDecoration.underline,
            decorationColor: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
