import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/settings/_widgets/list_tile.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/toast.dart';

const check = Icon(Symbols.check_rounded);
const loading = LoadingIcon();
const empty = Icon(null);

void showSuccessToast(BuildContext context) {
  showToast(context, ToastWidget.text('已更新通知設定', icon: const Icon(Symbols.check_rounded)));
}

void showErrorToast(BuildContext context) {
  showToast(context, ToastWidget.text('更新通知設定失敗', icon: const Icon(Symbols.error_rounded)));
}

Future setEewNotifyType(BuildContext context, EewNotifyType value, Future Function(EewNotifyType value) setter) async {
  try {
    await setter(value);

    if (!context.mounted) return;
    showSuccessToast(context);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context);
  }
}

Future setEarthquakeNotifyType(
  BuildContext context,
  EarthquakeNotifyType value,
  Future Function(EarthquakeNotifyType value) setter,
) async {
  try {
    await setter(value);

    if (!context.mounted) return;
    showSuccessToast(context);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context);
  }
}

Future setWeatherNotifyType(
  BuildContext context,
  WeatherNotifyType value,
  Future Function(WeatherNotifyType value) setter,
) async {
  try {
    await setter(value);

    if (!context.mounted) return;
    showSuccessToast(context);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context);
  }
}

Future setTsunamiNotifyType(
  BuildContext context,
  TsunamiNotifyType value,
  Future Function(TsunamiNotifyType value) setter,
) async {
  try {
    await setter(value);

    if (!context.mounted) return;
    showSuccessToast(context);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context);
  }
}

Future setBasicNotifyType(
  BuildContext context,
  BasicNotifyType value,
  Future Function(BasicNotifyType value) setter,
) async {
  try {
    await setter(value);

    if (!context.mounted) return;
    showSuccessToast(context);
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context);
  }
}
