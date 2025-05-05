import 'dart:async';

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
  Completer<List<ProductDetails>> products = Completer();

  final Set<String> _kIds = <String>{'s_donation75', 'donation100', 'donation300', 'donation1000'};

  Future<void> refresh() async {
    setState(() => products = Completer<List<ProductDetails>>());

    final isAvailable = await InAppPurchase.instance.isAvailable();

    if (!isAvailable) {
      products.completeError("無法連線至商店，請稍後再試");
      return;
    }

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      products.completeError("找不到商品，請稍候再試");
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

          return ListView(
            children: [
              SettingsListSection(
                children: [
                  for (final product in data)
                    SettingsListTile(
                      title: product.title,
                      subtitle: Text(product.description),
                      trailing: Text('${product.currencySymbol} ${product.price}'),
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
            ],
          );
        },
      ),
    );
  }
}
