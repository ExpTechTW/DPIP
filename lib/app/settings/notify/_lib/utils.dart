/// Utility helpers for notification settings pages.
///
/// Provides shared toast display functions and generic setters for each
/// notification type that show success or error feedback after the async
/// operation completes.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/toast.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A checkmark icon used as the selected-state trailing widget.
const check = Icon(Symbols.check_rounded);

/// A loading spinner used as the in-progress trailing widget.
const loading = LoadingIcon();

/// An empty icon used as the unselected trailing widget.
const empty = Icon(null);

/// Shows a success toast confirming the notification setting was updated.
void showSuccessToast(BuildContext context) {
  showToast(
    context,
    ToastWidget.text(
      '已更新通知設定'.i18n,
      icon: const Icon(Symbols.check_rounded),
    ),
  );
}

/// Shows an error toast indicating the notification setting update failed.
void showErrorToast(BuildContext context) {
  showToast(
    context,
    ToastWidget.text(
      '更新通知設定失敗'.i18n,
      icon: const Icon(Symbols.error_rounded),
    ),
  );
}

/// Calls [setter] with [value], then shows a success or error toast.
Future setEewNotifyType(
  BuildContext context,
  EewNotifyType value,
  Future Function(EewNotifyType value) setter,
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

/// Calls [setter] with [value], then shows a success or error toast.
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

/// Calls [setter] with [value], then shows a success or error toast.
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

/// Calls [setter] with [value], then shows a success or error toast.
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

/// Calls [setter] with [value], then shows a success or error toast.
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
