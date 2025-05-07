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
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  Completer<List<ProductDetails>> products = Completer()..future.onError((_, _) => []);

  final Set<String> _kIds = <String>{'s_donation75', 'donation100', 'donation300', 'donation1000'};

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
    refresh();
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
                        title: product.title.substring(0, product.title.indexOf('(')).trim(),
                        subtitle: Text(product.description),
                        trailing: Text('${product.price}/月'),
                        onTap: () {
                          if (product.isSubscription) {
                            InAppPurchase.instance.buyNonConsumable(
                              purchaseParam: PurchaseParam(productDetails: product),
                            );
                          } else {
                            InAppPurchase.instance.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
                          }
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
                        title: product.title.substring(0, product.title.indexOf('(')).trim(),
                        subtitle: Text(product.description),
                        trailing: Text(product.price),
                        onTap: () {
                          if (product.isSubscription) {
                            InAppPurchase.instance.buyNonConsumable(
                              purchaseParam: PurchaseParam(productDetails: product),
                            );
                          } else {
                            InAppPurchase.instance.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
                          }
                        },
                      ),
                  ],
                ),
              const SettingsListTextSection(
                content: '感謝您的慷慨支援與捐助！❤️\n此贊助屬自願性質，一經付款，恕不退還。所有款項將用於伺服器維護用途。若您有任何疑問，請於付款前與我們聯繫。',
                contentAlignment: TextAlign.justify,
              ),
            ],
          );
        },
      ),
    );
  }
}
