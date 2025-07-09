import 'dart:io';
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/product_detail.dart';
import 'package:dpip/utils/functions.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  StreamSubscription<List<PurchaseDetails>>? subscription;

  Future<void> refresh() async {
    setState(() => products = Completer<List<ProductDetails>>());

    final isAvailable = await InAppPurchase.instance.isAvailable();

    if (!isAvailable) {
      products.completeError('無法連線至商店，請稍後再試'.i18n);
      return;
    }

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      products.completeError('找不到商品，請稍候再試'.i18n);
      return;
    }

    products.complete(response.productDetails);
  }

  @override
  void initState() {
    super.initState();
    _refreshIndicatorKey.currentState?.show();

    subscription?.cancel();
    subscription = InAppPurchase.instance.purchaseStream.listen(
      onPurchaseUpdate,
      onError: (error) {
        setState(() => isPending = false);
      },
    );
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

        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (purchaseDetails.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(purchaseDetails);
          }
          setState(() => isPending = false);

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
                children: [Text(error.toString()), FilledButton.tonal(onPressed: refresh, child: Text('重新載入'.i18n))],
              ),
            );
          }

          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [const CircularProgressIndicator(), Text('正在載入商店物品中'.i18n)],
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
                ListSection(
                  title: '訂閱制'.i18n,
                  children: [
                    for (final product in subscriptions)
                      ListSectionTile(
                        title:
                            product.title.contains('(')
                                ? product.title.substring(0, product.title.indexOf('(')).trim()
                                : product.title,
                        subtitle: Text(product.description),
                        trailing: Text('{price}/月'.i18n.args({'price': product.price})),
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
                ListSection(
                  title: '單次支援'.i18n,
                  children: [
                    for (final product in oneTime)
                      ListSectionTile(
                        title:
                            product.title.contains('(')
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
              SettingsListTextSection(
                content: '感謝您的支持！❤️\n您所支付的款項將用於伺服器維護用途。若您有任何問題，歡迎於付款前與我們聯繫。'.i18n,
                contentAlignment: TextAlign.justify,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.restore),
                label: Text('恢復購買'.i18n),
                onPressed: () async {
                  final bool available = await InAppPurchase.instance.isAvailable();
                  if (!available) {
                    final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('無法連線至 $storeName，請稍後再試。')));
                    return;
                  }
                  InAppPurchase.instance.restorePurchases();

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在恢復您的購買的訂閱')));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
