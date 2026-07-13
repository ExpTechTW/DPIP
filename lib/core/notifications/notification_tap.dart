import 'package:flutter/foundation.dart';

/// A tapped notification, normalised from either ingress (FCM `message.data` or
/// an awesome action `payload`) to a channel key plus its data.
///
/// Carries enough to route to a screen and — once per-item detail routes exist —
/// to the specific item by [id]; the backend already sends it. Keeping the id on
/// the tap now (rather than discarding it at the String-channel boundary) means
/// deep-linking a report/event later is a localised change, not a spine rewrite.
@immutable
class NotificationTap {
  const NotificationTap({this.channelKey, this.data = const {}});

  /// Builds a tap from a raw data/payload map (FCM's dynamic values or awesome's
  /// nullable strings), dropping nulls and reading the channel from `channel`.
  factory NotificationTap.fromData(Map<String, dynamic>? raw) {
    final data = <String, String>{};
    raw?.forEach((key, value) {
      if (value != null) data[key] = value.toString();
    });
    return NotificationTap(channelKey: data['channel'], data: data);
  }

  /// The alert channel that fired (drives which screen the tap opens).
  final String? channelKey;

  /// The message's data payload.
  final Map<String, String> data;

  /// The target item id the backend sends (e.g. a report id), if any.
  String? get id => data['id'];
}
