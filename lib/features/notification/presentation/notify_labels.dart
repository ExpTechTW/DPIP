/// Localized titles, icons, and option labels for the notification channels —
/// the presentation-only mapping the settings page and its option sheet share.
library;

import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The channel's display title.
String notifyChannelTitle(NotifyChannel channel, AppLocalizations l10n) =>
    switch (channel) {
      NotifyChannel.eew => l10n.notifyEew,
      NotifyChannel.monitor => l10n.notifyMonitor,
      NotifyChannel.report => l10n.notifyReport,
      NotifyChannel.intensity => l10n.notifyIntensity,
      NotifyChannel.thunderstorm => l10n.notifyThunderstorm,
      NotifyChannel.weatherAdvisory => l10n.notifyAdvisory,
      NotifyChannel.evacuation => l10n.notifyEvacuation,
      NotifyChannel.tsunami => l10n.notifyTsunami,
      NotifyChannel.announcement => l10n.notifyAnnouncement,
    };

/// The channel's leading icon (outlined, per the icon convention) — one fixed
/// icon regardless of the current option; the subtitle carries the state.
IconData notifyChannelIcon(NotifyChannel channel) => switch (channel) {
  NotifyChannel.eew => Icons.crisis_alert_outlined,
  NotifyChannel.monitor => Icons.monitor_heart_outlined,
  NotifyChannel.report => Icons.description_outlined,
  NotifyChannel.intensity => Icons.summarize_outlined,
  NotifyChannel.thunderstorm => Icons.thunderstorm_outlined,
  NotifyChannel.weatherAdvisory => Icons.warning_amber_outlined,
  NotifyChannel.evacuation => Icons.directions_run_outlined,
  NotifyChannel.tsunami => Icons.tsunami_outlined,
  NotifyChannel.announcement => Icons.campaign_outlined,
};

/// The label for one option kind.
String notifyOptionLabel(NotifyOptionKind kind, AppLocalizations l10n) =>
    switch (kind) {
      NotifyOptionKind.off => l10n.notifyOptOff,
      NotifyOptionKind.all => l10n.notifyOptAll,
      NotifyOptionKind.localIntensity4 => l10n.notifyOptLocalIntensity4,
      NotifyOptionKind.localIntensity1 => l10n.notifyOptLocalIntensity1,
      NotifyOptionKind.weatherLocal => l10n.notifyOptWeatherLocal,
      NotifyOptionKind.tsunamiWarning => l10n.notifyOptTsunamiWarning,
      NotifyOptionKind.tsunamiAll => l10n.notifyOptTsunamiAll,
    };

/// The option's leading icon in the picker sheet — a coarse "how much" cue
/// (silenced, narrow threshold, or everything) shared by every channel's
/// option list, per DESIGN.md's "every menu row has a leading icon" rule.
IconData notifyOptionIcon(NotifyOptionKind kind) => switch (kind) {
  NotifyOptionKind.off => Icons.notifications_off_outlined,
  NotifyOptionKind.all => Icons.notifications_active_outlined,
  NotifyOptionKind.localIntensity4 => Icons.notification_important_outlined,
  NotifyOptionKind.localIntensity1 => Icons.notifications_outlined,
  NotifyOptionKind.weatherLocal => Icons.notifications_outlined,
  NotifyOptionKind.tsunamiWarning => Icons.notification_important_outlined,
  NotifyOptionKind.tsunamiAll => Icons.notifications_active_outlined,
};
