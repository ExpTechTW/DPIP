import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/utils/functions.dart';
import 'package:flutter/material.dart';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/utils/extensions/product_detail.dart';

class SettingsDonatePage extends StatefulWidget {
  const SettingsDonatePage({super.key});

  static const route = '/settings/donate';

  @override
  State<SettingsDonatePage> createState() => _SettingsDonatePageState();
}

class _SettingsDonatePageState extends State<SettingsDonatePage> {
  bool isPending = false;
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  Completer<List<ProductDetails>> products = Completer();

  final Set<String> _kIds = <String>{'s_donation75', 'donation100', 'donation300', 'donation1000'};
  late final StreamSubscription<List<PurchaseDetails>> subscription;

  Future<void> refresh() async {
    setState(() => products = Completer<List<ProductDetails>>());

    final isAvailable = await InAppPurchase.instance.isAvailable();

    if (!isAvailable) {
      products.completeError('無法連線至商店，請稍後再試');
      return;
    }

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      products.completeError('找不到商品，請稍候再試');
      return;
    }

    products.complete(response.productDetails);
  }

  @override
  void initState() {
    super.initState();
    _refreshIndicatorKey.currentState?.show();

    subscription = InAppPurchase.instance.purchaseStream.listen(onPurchaseUpdate, onError: (error) {
      setState(() => isPending = false);
    });
    refresh();
  }

  void onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchaseDetails.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(purchaseDetails);
          }
          setState(() => isPending = false);
          break;

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (purchaseDetails.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(purchaseDetails);
          }
          setState(() => isPending = false);
          break;

        case PurchaseStatus.pending:
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
                children: [Text(error.toString()), FilledButton.tonal(onPressed: refresh, child: const Text('重新載入'))],
              ),
            );
          }

          if (data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [CircularProgressIndicator(), Text('正在載入商店物品中')],
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
            children: [
              if (subscriptions.isNotEmpty)
                SettingsListSection(
                  title: '訂閱制',
                  children: [
                    for (final product in subscriptions)
                      SettingsListTile(
                        title: product.title.contains('(')
                            ? product.title.substring(0, product.title.indexOf('(')).trim()
                            : product.title,
                        subtitle: Text(product.description),
                        trailing: Text('${product.price}/月'),
                        onTap: () {
                          if (isPending) return;
                          setState(() => isPending = true);
                          final purchaseParam = PurchaseParam(productDetails: product);
                          InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
                        },
                      ),
                  ],
                ),
              if (oneTime.isNotEmpty)
                SettingsListSection(
                  title: '單次支援',
                  children: [
                    for (final product in oneTime)
                      SettingsListTile(
                        title: product.title.contains('(')
                            ? product.title.substring(0, product.title.indexOf('(')).trim()
                            : product.title,
                        subtitle: Text(product.description),
                        trailing: Text(product.price),
                        onTap: () {
                          if (isPending) return;
                          setState(() => isPending = true);
                          final purchaseParam = PurchaseParam(productDetails: product);
                          InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
                        },
                      ),
                  ],
                ),
              const SettingsListTextSection(
                content: '感謝您的支持！❤️\n您所支付的款項將用於伺服器維護用途。若您有任何問題，歡迎於付款前與我們聯繫。',
                contentAlignment: TextAlign.justify,
              ),
              // FilledButton.tonalIcon(
              //   icon: const Icon(Icons.restore),
              //   label: const Text('恢復購買'),
              //   onPressed: () {
              //     InAppPurchase.instance.restorePurchases();
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('已開始恢復先前的購買項目（不包含單次支援的購買）')),
              //     );
              //   },
              // ),
            ],
          );
        },
      ),
    );
  }
}
